//
// SADatabaseUnitTest.m
// SensorsAnalyticsTests
//
// Created by 陈玉国 on 2020/6/17.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SADatabase.h"
#import "SensorsAnalyticsSDK.h"

@interface SADatabaseUnitTest : XCTestCase

@property (nonatomic, strong) SADatabase *database;

@end

@implementation SADatabaseUnitTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.db"];
    self.database = [[SADatabase alloc] initWithFilePath:path];
    self.database.maxCacheSize = 20000;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.db"];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    self.database = nil;
}

- (void)testDBInstance {
    XCTAssertTrue(self.database != nil);
}

//- (void)testDBOpen {
//    XCTAssertTrue([self.database open]);
//}
//
//- (void)testDBCreateTable {
//    XCTAssertTrue([self.database createTable]);
//}

- (void)testInsertSingleRecord {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInsertSingleRecord"];
    NSString *content = @"testInsertSingleRecord";
    NSString *type = @"POST";
    SAEventRecord *record = [[SAEventRecord alloc] init];
    record.content = content;
    record.type = type;
    [self.database insertRecord:record completion:^(BOOL success) {
        if (success) {
            [self.database fetchRecords:1 Completion:^(NSArray<SAEventRecord *> * _Nonnull records) {
                SAEventRecord *record = records.firstObject;
                XCTAssertTrue(record != nil && [record.content isEqualToString:content]);
                [expectation fulfill];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"insert single record timeout");
    }];
}

- (void)testFetchRecord {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInsertSingleRecord"];
    NSString *content = @"testFetchRecord";
    NSString *type = @"POST";
    SAEventRecord *record = [[SAEventRecord alloc] init];
    record.content = content;
    record.type = type;
    [self.database insertRecord:record completion:^(BOOL success) {
        if (success) {
            [self.database fetchRecords:1 Completion:^(NSArray<SAEventRecord *> * _Nonnull records) {
                SAEventRecord *record = records.firstObject;
                XCTAssertTrue(record != nil && [record.content isEqualToString:content]);
                [expectation fulfill];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"insert single record timeout");
    }];
}

- (void)testDeleteRecords {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testBulkInsertRecords"];
    NSMutableArray<SAEventRecord *> *tempRecords = [NSMutableArray array];
    for (NSUInteger index = 0; index < 10000; index++) {
        NSString *content = [NSString stringWithFormat:@"testBulkInsertRecords_%lu",index];
        NSString *type = @"POST";
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.content = content;
        record.type = type;
        [tempRecords addObject:record];
    }
    [self.database insertRecords:tempRecords completion:^(BOOL success) {
        if (success) {
            [self.database fetchRecords:10000 Completion:^(NSArray<SAEventRecord *> * _Nonnull records) {
                NSMutableArray <NSString *> *recordIDs = [NSMutableArray array];
                for (SAEventRecord *record in records) {
                    [recordIDs addObject:record.recordID];
                }
                [self.database deleteRecords:recordIDs completion:^(BOOL success) {
                    [self.database fetchRecords:NSUIntegerMax Completion:^(NSArray<SAEventRecord *> * _Nonnull records) {
                        XCTAssertTrue(records.count == 0);
                        [expectation fulfill];
                    }];
                }];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:50 handler:^(NSError * _Nullable error) {
        NSLog(@"insert single record timeout");
    }];
}

- (void)testBulkInsertRecords {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testBulkInsertRecords"];
    NSMutableArray<SAEventRecord *> *tempRecords = [NSMutableArray array];
    for (NSUInteger index = 0; index < 10000; index++) {
        NSString *content = [NSString stringWithFormat:@"testBulkInsertRecords_%lu",index];
        NSString *type = @"POST";
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.content = content;
        record.type = type;
        [tempRecords addObject:record];
    }
    [self.database insertRecords:tempRecords completion:^(BOOL success) {
        if (success) {
            [self.database fetchRecords:10000 Completion:^(NSArray<SAEventRecord *> * _Nonnull records) {
                BOOL success = YES;
                if (records.count != 10000) {
                    XCTAssertFalse(true);
                    [expectation fulfill];
                    return;
                }
                for (NSUInteger index; index < 10000; index++) {
                    if (![records[index].content isEqualToString:tempRecords[index].content]) {
                        success = NO;
                    }
                }
                XCTAssertTrue(success);
                [expectation fulfill];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:50 handler:^(NSError * _Nullable error) {
        NSLog(@"insert single record timeout");
    }];
}

- (void)testDeleteAllRecords {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInsertSingleRecord"];
    NSMutableArray<SAEventRecord *> *tempRecords = [NSMutableArray array];
    for (NSUInteger index = 0; index < 10000; index++) {
        NSString *content = [NSString stringWithFormat:@"testBulkInsertRecords_%lu",index];
        NSString *type = @"POST";
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.content = content;
        record.type = type;
        [tempRecords addObject:record];
    }
    [self.database insertRecords:tempRecords completion:^(BOOL success) {
        if (success) {
            [self.database deleteAllRecordsWithCompletion:^(BOOL success) {
                if (success) {
                    [self.database fetchRecords:100 Completion:^(NSArray<SAEventRecord *> * _Nonnull records) {
                        XCTAssertTrue(records.count == 0);
                        [expectation fulfill];
                    }];
                }
            }];
        }
    }];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"insert single record timeout");
    }];
}

@end
