//
//  MessageQueueBySqlite.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAEventRecord : NSObject

@property (nonatomic, copy) NSString *recordID;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *type;

- (instancetype)initWithContent:(NSString *)content type:(NSString *)type;

@end


/**
 *  @abstract
 *  一个基于Sqlite封装的接口，用于向其中添加和获取数据
 */
@interface SADatabase : NSObject

//serial queue for database read and write
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;
@property (nonatomic, assign) NSUInteger maxCacheSize;

/// init method
/// @param filePath path for database file
- (instancetype)initWithFilePath:(NSString *)filePath;


/// open database, return YES or NO
- (BOOL)open;


/// create default event table, return YES or NO
- (BOOL)createTable;

/// fetch first records with a certain size
/// @param recordSize record size
- (NSArray<SAEventRecord *> *)fetchRecords:(NSUInteger)recordSize;


/// bulk insert event records
/// @param records event records
- (BOOL)insertRecords:(NSArray<SAEventRecord *> *)records;


/// insert single record
/// @param record event record
- (BOOL)insertRecord:(SAEventRecord *)record;


/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


/// delete first records with a certain size
/// @param recordSize record size
- (BOOL)deleteFirstRecords:(NSUInteger)recordSize;


/// delete all records from database
- (BOOL)deleteAllRecords;


/// event record count stored in database
- (NSUInteger)messagesCount;

/**
 *  @abstract
 *  缩减表格文件空洞数据的空间
 *
 *  @return 是否成功
 */
- (BOOL) vacuum;

@end

NS_ASSUME_NONNULL_END
