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

/**
 *  @abstract
 *  根据传入的文件路径初始化
 *
 *  @param filePath 传入的数据文件路径
 *
 *  @return 初始化的结果
 */
- (instancetype)initWithFilePath:(NSString *)filePath;


/// fetch records
/// @param recordSize records size
/// @param completion if fetching records successfully, error is nil and get an array of records, otherwise, error is not nil, and records array should be empty
- (void)fetchRecords:(NSUInteger)recordSize Completion:(void (^)(NSArray<SAEventRecord *> *records))completion;

/// insert single record to database
/// @param record event record object
/// @param completion completion handler, insert successfully, then error is nil, otherwise, error return
- (void)insertRecord:(SAEventRecord *)record completion:(void (^)(BOOL success))completion;


/// bulk insert records
/// @param records event records
/// @param completion completion handler, insert successfully, then error is nil, otherwise, error return
- (void)insertRecords:(NSArray<SAEventRecord *> *)records completion:(void (^)(BOOL success))completion;

/// delete records
/// @param recordIDs an array of event id in database table
/// @param completion completion handler, delete successfully, then error is nil, otherwise, error return
- (void)deleteRecords:(NSArray<NSString *> *)recordIDs completion:(void (^)(BOOL success))completion;

/// delete all records
/// @param completion completion handler, delete successfully, then error is nil, otherwise, error return
- (void) deleteAllRecordsWithCompletion:(void (^)(BOOL success))completion;

/**
 *  @abstract
 *  获取当前记录的数量
 *
 *  @return 当前记录的数量
 */
- (NSInteger) count;

/**
 *  @abstract
 *  缩减表格文件空洞数据的空间
 *
 *  @return 是否成功
 */
- (BOOL) vacuum;

@end

NS_ASSUME_NONNULL_END
