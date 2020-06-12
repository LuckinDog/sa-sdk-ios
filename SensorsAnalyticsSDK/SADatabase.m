//
//  MessageQueueBySqlite.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <sqlite3.h>
#import "SAJSONUtil.h"
#import "SADatabase.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"

static const NSUInteger kRemoveFirstRecordsDefaultCount = 100; // 超过最大缓存条数时默认的删除条数

@implementation SAEventRecord

- (instancetype)initWithContent:(NSString *)content type:(NSString *)type {
    if (self = [super init]) {
        self.content = content;
        self.type = type;
    }
    return self;
}

@end

@interface SADatabase ()

@property (nonatomic, copy) NSString *filePath;
/// store data in memory
@property (nonatomic, strong) NSMutableArray<NSString *> *messageCaches;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, assign) BOOL isCreatedTable;

@end

@implementation SADatabase {
    sqlite3 *_database;
    CFMutableDictionaryRef _dbStmtCache;
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.filePath = filePath;
        _serialQueue = dispatch_queue_create("cn.sensorsdata.SADatabaseSerialQueue", DISPATCH_QUEUE_SERIAL);
        [self createStmtCache];
        [self open];
        [self createTable];
    }
    return self;
}

- (BOOL)open {
    if (self.isOpen) {
        return YES;
    }
    if (_database) {
        [self close];
    }
    if (sqlite3_open_v2([self.filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
        _database = NULL;
        SALogError(@"Failed to open SQLite db");
        return NO;
    }
    SALogDebug(@"Success to open SQLite db");
    self.isOpen = YES;
    return YES;
}

- (void)close {
    if (_dbStmtCache) CFRelease(_dbStmtCache);
    _dbStmtCache = NULL;
    sqlite3_close(_database);
    sqlite3_shutdown();
    SALogDebug(@"%@ close database", self);
}

- (BOOL)databaseCheck {
    if (![self open]) {
        return NO;
    }
    if (![self createTable]) {
        return NO;
    }
    return YES;
}

//MARK: Public APIs for database CRUD
- (void)fetchRecords:(NSUInteger)recordSize Completion:(void (^)(NSArray<SAEventRecord *> * _Nonnull))completion {
    dispatch_async(self.serialQueue, ^{
        completion([self fetchRecords:recordSize]);
    });
}

- (void)insertRecords:(NSArray<SAEventRecord *> *)records completion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        completion([self insertRecords:records]);
    });
}

- (void)insertRecord:(SAEventRecord *)record completion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        completion([self insertRecord:record]);
    });
}

- (void)deleteRecords:(NSArray<NSString *> *)recordIDs completion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        completion([self deleteRecords:recordIDs]);
    });
}

- (void)deleteAllRecordsWithCompletion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        completion([self deleteAllRecords]);
    });
}

// MARK: Internal APIs for database CRUD
- (BOOL)createTable {
    if (!self.isOpen) {
        return NO;
    }
    if (self.isCreatedTable) {
        return YES;
    }
    NSString *sql = @"create table if not exists dataCache (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT)";
    if (sqlite3_exec(_database, sql.UTF8String, NULL, NULL, NULL) != SQLITE_OK) {
        SALogError(@"Create dataCache table fail.");
        self.isCreatedTable = NO;
        return NO;
    }
    self.isCreatedTable = YES;
    SALogDebug(@"Create dataCache table success, current count is %lu", [self messagesCount]);
    return YES;
}

- (NSArray<SAEventRecord *> *)fetchRecords:(NSUInteger)recordSize {
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    if (([self messagesCount] == 0) || (recordSize == 0)) {
        return [contentArray copy];
    }
    if (![self databaseCheck]) {
        return [contentArray copy];
    }
    NSString *query = [NSString stringWithFormat:@"SELECT id,content FROM dataCache ORDER BY id ASC LIMIT %lu", (unsigned long)recordSize];
    sqlite3_stmt *stmt = [self dbCacheStmt:query];
    if (!stmt) {
        SALogError(@"Failed to prepare statement, error:%s", sqlite3_errmsg(_database));
        return [contentArray copy];
    }

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int index = sqlite3_column_int(stmt, 0);
        char *jsonChar = (char *)sqlite3_column_text(stmt, 1);
        if (!jsonChar) {
            SALogError(@"Failed to query column_text, error:%s", sqlite3_errmsg(_database));
            return @[];
        }
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.recordID = [NSString stringWithFormat:@"%d",index];
        record.content = [NSString stringWithUTF8String:jsonChar];
        [contentArray addObject:record];
    }

    return [contentArray copy];
}

- (BOOL)insertRecords:(NSArray<SAEventRecord *> *)records {
    if (records.count == 0) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    if (sqlite3_exec(_database, "BEGIN TRANSACTION", 0, 0, 0) != SQLITE_OK) {
        return NO;
    }

    NSString *query = @"INSERT INTO dataCache(type, content) values(?, ?)";
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    if (!insertStatement) {
        return NO;
    }
    BOOL success = YES;
    for (SAEventRecord *record in records) {
        if (!record.content || ![record.type isKindOfClass:[NSString class]]) {
            success = NO;
            break;
        }
        sqlite3_bind_text(insertStatement, 1, [record.type UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, [record.content UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(insertStatement) != SQLITE_DONE) {
            success = NO;
            break;
        }
        sqlite3_reset(insertStatement);
    }
    sqlite3_finalize(insertStatement);
    return sqlite3_exec(_database, success ? "COMMIT" : "ROLLBACK", 0, 0, 0) == SQLITE_OK;
}

- (BOOL)insertRecord:(SAEventRecord *)record {
    BOOL success = NO;
    if (!record.content || ![record.type isKindOfClass:[NSString class]]) {
        SALogError(@"%@ input parameter is invalid for addObjectToDatabase", self);
        return success;
    }
    if (![self databaseCheck]) {
        return NO;
    }

    if (![self preCheckForInsertRecords:1]) {
        return NO;
    }

    NSString *query = @"INSERT INTO dataCache(type, content) values(?, ?)";
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    int rc;
    if (insertStatement) {
        sqlite3_bind_text(insertStatement, 1, [record.type UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, [record.content UTF8String], -1, SQLITE_TRANSIENT);
        rc = sqlite3_step(insertStatement);
        if (rc != SQLITE_DONE) {
            SALogError(@"insert into dataCache table of sqlite fail, rc is %d", rc);
            return success;
        }
        SALogDebug(@"insert into dataCache table of sqlite success, current count is %lu", [self messagesCount]);
        success = YES;
        return success;
    } else {
        SALogError(@"insert into dataCache table of sqlite error");
        return success;
    }
}

- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs {
    if (([self messagesCount] == 0) || (recordIDs.count == 0)) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *query = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id IN (%@);", [recordIDs componentsJoinedByString:@","]];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        SALogError(@"Prepare delete records query failure: %s", sqlite3_errmsg(_database));
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        SALogError(@"Failed to delete record from database, error: %s", sqlite3_errmsg(_database));
    }
    sqlite3_finalize(stmt);
    return YES;
}

- (BOOL)deleteFirstRecords:(NSUInteger)recordSize {
    if ([self messagesCount] == 0 || recordSize == 0) {
        return YES;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSUInteger removeSize = MIN(recordSize, [self messagesCount]);
    NSString *query = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id IN (SELECT id FROM dataCache ORDER BY id ASC LIMIT %lu);", (unsigned long)removeSize];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        SALogError(@"Prepare delete records query failure: %s", sqlite3_errmsg(_database));
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        SALogError(@"Failed to delete record from database, error: %s", sqlite3_errmsg(_database));
    }
    sqlite3_finalize(stmt);
    return YES;
}

- (BOOL)deleteAllRecords {
    [self.messageCaches removeAllObjects];
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *sql = @"DELETE FROM dataCache";
    if (sqlite3_exec(_database, sql.UTF8String, NULL, NULL, NULL) != SQLITE_OK) {
        SALogError(@"Failed to delete all records");
        return NO;
    }
    return YES;
}

- (BOOL)preCheckForInsertRecords:(NSUInteger)recordSize {
    if (recordSize > self.maxCacheSize) {
        return NO;
    }
    while (([self messagesCount] + recordSize) >= self.maxCacheSize) {
        SALogWarn(@"AddObjectToDatabase touch MAX_MESSAGE_SIZE:%lu, try to delete some old events", self.maxCacheSize);
        if (![self deleteFirstRecords:kRemoveFirstRecordsDefaultCount]) {
            SALogError(@"AddObjectToDatabase touch MAX_MESSAGE_SIZE:%lu, try to delete some old events FAILED", self.maxCacheSize);
            return NO;
        }
    }
    return YES;
}

- (void)createStmtCache {
    CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
    CFDictionaryValueCallBacks valueCallbacks = { 0 };
    _dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
}

- (NSInteger)count {
    return [self messagesCount] + self.messageCaches.count;
}

- (BOOL)vacuum {
#ifdef SENSORS_ANALYTICS_ENABLE_VACUUM
    @try {
        if (![self databaseCheck]) {
            SALogError(@"Failed to VACUUM record because the database failed to open");
            return NO;
        }
        
        NSString *sql = @"VACUUM";
        if (![self databaseExecute:sql]) {
            SALogError(@"Failed to VACUUM record");
            return NO;
        }
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
#else
    return YES;
#endif
}

- (sqlite3_stmt *)dbCacheStmt:(NSString *)sql {
    if (sql.length == 0 || !_dbStmtCache) return NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(_dbStmtCache, (__bridge const void *)(sql));
    if (!stmt) {
        int result = sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL);
        if (result != SQLITE_OK) {
            SALogError(@"sqlite stmt prepare error (%d): %s", result, sqlite3_errmsg(_database));
            return NULL;
        }
        CFDictionarySetValue(_dbStmtCache, (__bridge const void *)(sql), stmt);
    } else {
        sqlite3_reset(stmt);
    }
    return stmt;
}

- (NSUInteger)messagesCount {
    NSString *query = @"select count(*) from dataCache";
    int count = 0;
    sqlite3_stmt *statement = [self dbCacheStmt:query];
    if (statement) {
        while (sqlite3_step(statement) == SQLITE_ROW)
            count = sqlite3_column_int(statement, 0);
    } else {
        SALogError(@"Failed to prepare statement");
    }
    return (NSUInteger)count;
}

#pragma mark - Getters and Setters
- (NSMutableArray<NSString *> *)messageCaches {
    if (!_messageCaches) {
        _messageCaches = [NSMutableArray array];
    }
    return _messageCaches;
}

#pragma mark - Life Cycle
- (void)dealloc {
    [self close];
}

@end
