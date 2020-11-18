//
//  UTCTime.m
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "UTCTime.h"

@implementation UTCTime

+(NSTimeInterval) getUTCTimeSecond
{
    return [[NSDate date] timeIntervalSince1970];
}

+(UTCTime*) getLocalTimeFromUTC: (int)hour minute:(int) minute second:(int) second
{
    NSString *utcTimeStr = [NSString stringWithFormat:@"2000-01-01 %02d:%02d:%02d",
                         hour, minute, second];
    
    NSDateFormatter *utcFormat = [[NSDateFormatter alloc] init];
    utcFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    utcFormat.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSDate *utcDate = [utcFormat dateFromString:utcTimeStr];
    
    NSDateFormatter *formatLocal = [[NSDateFormatter alloc] init];
    formatLocal.dateFormat = @"HH:mm:ss";
    formatLocal.timeZone = [NSTimeZone localTimeZone];
    NSString *dateString = [formatLocal stringFromDate:utcDate];
    
    UTCTime* utcTime = [[UTCTime alloc]init];
    NSArray * arr = [dateString componentsSeparatedByString:@":"];
    if (arr.count == 3)
    {
        utcTime.mHours = [arr[0] intValue];
        utcTime.mMinutes = [arr[1] intValue];
        utcTime.mSeconds = [arr[2] intValue];
    }
    
    return utcTime;
}

+(UTCTime*) getUTCFromLocalTime:(int)hour minute:(int)minute second:(int)seconds
{
    NSDateFormatter *dateFormatLocal = [[NSDateFormatter alloc] init];
    [dateFormatLocal setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* strLocalDate = [NSString stringWithFormat:@"2000-01-01 %02d:%02d:%02d",
                           hour,
                           minute,
                           seconds];
    NSDate *dateLocal = [dateFormatLocal dateFromString:strLocalDate];
    
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSDateFormatter *dateFormatUtc = [[NSDateFormatter alloc] init];
    [dateFormatUtc setDateFormat:@"HH:mm:ss"];
    [dateFormatUtc setTimeZone:timeZone];
    NSString *dateString = [dateFormatUtc stringFromDate:dateLocal];
    
    UTCTime* utcTime = [[UTCTime alloc]init];
    NSArray * arr = [dateString componentsSeparatedByString:@":"];
    if (arr.count == 3)
    {
        utcTime.mHours = [arr[0] intValue];
        utcTime.mMinutes = [arr[1] intValue];
        utcTime.mSeconds = [arr[2] intValue];
    }
    
    return utcTime;
}
@end
