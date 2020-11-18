//
//  CfgHTRecordFileMgr.m
//  KBeacon
//
//  Created by hogen on 2020/11/6.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "CfgHTRecordFileMgr.h"
#import "KBHumidityRecord.h"
#import "string.h"

#define RECORD_FILE_NAME_PREFEX @"_ht_sensor_record.txt"
#define RECORD_FILE_NAME @"_ht_sensor_record.txt"

@implementation CfgHTRecordFileMgr
{
    NSString* mRecordFileName;
    NSString* mDeviceMac;
    BOOL mIsFileChange;
}

-(NSString *)bundlePath:(NSString *)fileName {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}

-(NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

-(id)init:(NSString*)strMac
{
    self = [super init];

    NSString* strMacAddress = [strMac stringByReplacingOccurrencesOfString:@":" withString:@""];
    mRecordFileName= [NSString stringWithFormat:@"%@%@", strMacAddress , RECORD_FILE_NAME_PREFEX];
    NSString* strPath = [self documentsPath:mRecordFileName];
    mDeviceMac = strMacAddress;
    
    NSArray* pRecordArray = [NSArray arrayWithContentsOfFile:strPath];
    _mSensorRecordList = [[NSMutableArray alloc]init];
    /*
    _mSensorRecordList = [pRecordArray mutableCopy];
    */
    if (pRecordArray != nil)
    {
        for (NSDictionary* dict in pRecordArray)
        {
            KBHumidityRecord* record = [[KBHumidityRecord alloc]init:dict];
            [_mSensorRecordList addObject:record];
        }
    }

    mIsFileChange = NO;
    
    return self;
}


-(NSUInteger) size
{
    return self.mSensorRecordList.count;
}


-(KBHumidityRecord*) get:(NSUInteger) nIndex
{
    NSUInteger nMaxIndex = self.mSensorRecordList.count - 1;
    
    NSUInteger nReverseIndex =  nMaxIndex - nIndex;
    return [self.mSensorRecordList objectAtIndex:nReverseIndex];
}

-(void) clearHistoryRecord
{
    [self.mSensorRecordList removeAllObjects];

    [self saveRecordsToFile];
}

-(void) appendRecords:(NSMutableArray<KBHumidityRecord*>*) recordList
{
    for (KBHumidityRecord *record in recordList)
    {
        [self.mSensorRecordList addObject:record];
    }
    mIsFileChange = YES;
}

-(void) appendRecord:(KBHumidityRecord*) record
{
    [self.mSensorRecordList addObject:record];
    mIsFileChange = YES;
}

-(void) saveRecordsToFile
{
    if (mIsFileChange)
    {
        NSString* strPath = [self documentsPath:mRecordFileName];
        
        NSMutableArray* saveArray = [[NSMutableArray alloc]init];
        for (KBHumidityRecord* record in self.mSensorRecordList)
        {
            [saveArray addObject:[record toDictory]];
        }
        
        //write content to file
        BOOL bWriteRslt = [saveArray writeToFile:strPath atomically:YES];
        if (!bWriteRslt)
        {
            NSLog(@"write data to file failed");
        }
    }
}

-(NSString*) exportRecordsToString
{
    if (self.mSensorRecordList.count <= 0)
    {
        return nil;
    }
    
    NSMutableString* strBUilder = [[NSMutableString alloc]initWithCapacity:4096];
    [strBUilder appendString:@"mailto:your_email@example.com?"];
    
    //title
    NSString* strTitle = [NSString stringWithFormat:EXPORT_SENSOR_HISTORY_DATA_TITLE,mDeviceMac];
    [strBUilder appendString:strTitle];

    NSString* strWriteLine = @"&body=UTC \t Temperature \t Humidity\n";
    [strBUilder appendString:strWriteLine];

    for (KBHumidityRecord *record in self.mSensorRecordList)
    {
        NSString* strNearbyUtcTime = [self localTimeFromUTCSeconds: [record.utcTime longValue]];
        
        strWriteLine = [NSString stringWithFormat:@"%@\t%.2f\t%.2f\n",
                        strNearbyUtcTime,
                        [record.temperature floatValue],
                        [record.humidity floatValue]];
         [strBUilder appendString:strWriteLine];
    }
    
    return strBUilder;
}

-(NSString*) localTimeFromUTCSeconds:(long)utcSecond
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:utcSecond];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}


@end
