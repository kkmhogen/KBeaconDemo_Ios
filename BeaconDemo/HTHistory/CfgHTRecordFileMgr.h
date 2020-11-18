//
//  CfgHTRecordFileMgr.h
//  KBeacon
//
//  Created by hogen on 2020/11/6.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBHumidityRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface CfgHTRecordFileMgr : NSObject

@property (strong, nonatomic) NSMutableArray<KBHumidityRecord*> *mSensorRecordList;

-(id)init:(NSString*)strMac;

-(NSUInteger) size;

-(KBHumidityRecord*)get:(NSUInteger)nIndex;

-(void) appendRecords:(NSMutableArray<KBHumidityRecord*>*) recordList;

-(void) appendRecord:(KBHumidityRecord*) record;

-(NSString*)exportRecordsToString;

-(void)saveRecordsToFile;

-(void)clearHistoryRecord;

@end

NS_ASSUME_NONNULL_END
