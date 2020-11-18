//
//  KBCfgNearbyTrigger.m
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBCfgNearbyTrigger.h"
#import "KBException.h"
#import "KBCfgSleepTime.h"
#import "UTCTime.h"

@implementation KBCfgNearbyTrigger
{
    NSNumber* nbSleepTime;
}

@synthesize nbALmInterval = _nbALmInterval;
@synthesize nbALmDuration = _nbALmDuration;

-(void)setNbScanInterval:(NSNumber*) nbScanInterval
{
    if ([nbScanInterval intValue]  <= 10000 && [nbScanInterval intValue] >= 20)
    {
        _nbScanInterval = nbScanInterval;
    }else{
       @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby scan interval invalid"];
    }
}

-(void)setNbScanWindow:(NSNumber*) nbScanWindow
{
    if ([nbScanWindow intValue] <= 10000 && [nbScanWindow intValue] >= 20)
    {
        _nbScanWindow = nbScanWindow;
    }else{
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info: @"nearby scan window invalid"];
    }
}

-(void) setNbAdvTxPower:(NSNumber*)nbAdvTxPower
{
    _nbAdvTxPower = nbAdvTxPower;
}

-(void) setNbAdvInterval:(NSNumber*)nbAdvInterval
{
    if ([nbAdvInterval intValue] <= 10000 && [nbAdvInterval intValue]>= 20) {
        _nbAdvInterval = nbAdvInterval;
    }else{
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby adv interval invalid"];
    }
}

//uint is 100ms
-(void) setNbALmInterval:(NSNumber*)nbALmInterval
{
    int nDeviceAlmItvl = [nbALmInterval intValue] / 100;
    if (nDeviceAlmItvl > 0 && nDeviceAlmItvl < 200)
    {
        _nbALmInterval = [NSNumber numberWithInt:nDeviceAlmItvl];
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby alarm interval invalid"];
    }
}

-(NSNumber*) nbALmInterval
{
    return [NSNumber numberWithInt:[_nbALmInterval intValue] * 100];
}

//uint is 10ms
-(void) setNbALmDuration:(NSNumber*)nbALmDuration
{
    int nDeviceAlmDuration = [nbALmDuration intValue] / 10;
    if (nDeviceAlmDuration > 0 && nDeviceAlmDuration < 200)
    {
        _nbALmDuration = [NSNumber numberWithInt:nDeviceAlmDuration];
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby alarm interval invalid"];
    }
}

-(NSNumber*) nbALmDuration
{
    return [NSNumber numberWithInt:[_nbALmDuration intValue] * 10];
}

-(void) setNbAlmDistance:(NSNumber*)nbAlmDistance
{
    _nbAlmDistance = nbAlmDistance;
}

-(void) setNbAlmFactory:(NSNumber*)nbAlmFactory
{
    if ([nbAlmFactory intValue] > 30 || [nbAlmFactory intValue]< 10)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby alarm interval invalid"];
    }
    _nbAlmFactory = nbAlmFactory;
}

-(void) setNbSleepUtcTime:(KBCfgSleepTime*) sleepTime
{
    if (sleepTime.mSleepStartHour > 24 || sleepTime.mSleepStartMinute > 59 ||
            sleepTime.mSleepEndHour > 24 || sleepTime.mSleepEndMinute > 59)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby alarm interval invalid"];
    }

    long nSleepTime = 0;
    if (!(sleepTime.mSleepEndHour == sleepTime.mSleepStartHour && sleepTime.mSleepEndMinute == sleepTime.mSleepStartMinute))
    {
        nSleepTime = (Byte) sleepTime.mSleepStartHour;
        nSleepTime = (nSleepTime << 8);
        nSleepTime += (Byte) sleepTime.mSleepStartMinute;
        nSleepTime = (nSleepTime << 8);

        nSleepTime += (Byte) sleepTime.mSleepEndHour;
        nSleepTime = (nSleepTime << 8);
        nSleepTime += (Byte) sleepTime.mSleepEndMinute;
    }

    self->nbSleepTime = [NSNumber numberWithLong: nSleepTime];
}

-(void) setNbSleepLocalTime:(KBCfgSleepTime*) sleepTime
{
    if (sleepTime.mSleepStartHour > 24 || sleepTime.mSleepStartMinute > 59 ||
            sleepTime.mSleepEndHour > 24 || sleepTime.mSleepEndMinute > 59)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"nearby alarm interval invalid"];
    }

    long nSleepTime = 0;
    if (!(sleepTime.mSleepEndHour == sleepTime.mSleepStartHour && sleepTime.mSleepEndMinute == sleepTime.mSleepStartMinute))
    {
        UTCTime* utcStart = [UTCTime getUTCFromLocalTime:sleepTime.mSleepStartHour
                                                  minute:sleepTime.mSleepStartMinute
                                                  second: 0];
        nSleepTime = (Byte) utcStart.mHours;
        nSleepTime = (nSleepTime << 8);
        nSleepTime += (Byte) utcStart.mMinutes;
        nSleepTime = (nSleepTime << 8);

        UTCTime* utcStop = [UTCTime getUTCFromLocalTime: sleepTime.mSleepEndHour
                                                 minute: sleepTime.mSleepEndMinute
                                                 second:0];
        nSleepTime += (Byte) utcStop.mHours;
        nSleepTime = (nSleepTime << 8);
        nSleepTime += (Byte) utcStop.mMinutes;

        NSLog(@"set sleep time to:%ld,sh:%d, sm:%d, eh:%d, em:%d",
              nSleepTime,
              utcStart.mHours,
              utcStart.mMinutes,
              utcStop.mHours,
              utcStop.mMinutes);
    }

    self->nbSleepTime = [NSNumber numberWithLong: nSleepTime];
}

-(BOOL) isNBSleepEnable
{
    long nSleepTime = [self->nbSleepTime longValue];
    int sleepStart = (int)((nSleepTime >> 16) & 0xFFFF);
    int sleepEnd = (int)(nSleepTime & 0xFFFF);
    if (sleepStart == sleepEnd)
    {
        return false;
    }
    else
    {
        return true;
    }
}

-(NSNumber*) getNbAdvTxPower {
    return _nbAdvTxPower;
}

-(KBCfgSleepTime*) getNbSleepUtcTime
{
    long nSleepTime = [self->nbSleepTime longValue];

    KBCfgSleepTime* sleepTime = [[KBCfgSleepTime alloc]init];
    sleepTime.mSleepStartHour = (Byte)((nSleepTime >> 24) & 0xFF);
    sleepTime.mSleepStartMinute = (Byte)((nSleepTime >> 16) & 0xFF);
    sleepTime.mSleepEndHour = (Byte)((nSleepTime >> 8) & 0xFF);
    sleepTime.mSleepEndMinute = (Byte)(nSleepTime & 0xFF);

    return sleepTime;
}


-(KBCfgSleepTime*) getNbSleepLocalTime
{
    long nSleepTime = [self->nbSleepTime longValue];

    KBCfgSleepTime* sleepTime = [[KBCfgSleepTime alloc]init];
    sleepTime.mSleepStartHour = (Byte)((nSleepTime >> 24) & 0xFF);
    sleepTime.mSleepStartMinute = (Byte)((nSleepTime >> 16) & 0xFF);
    sleepTime.mSleepEndHour = (Byte)((nSleepTime >> 8) & 0xFF);
    sleepTime.mSleepEndMinute = (Byte)(nSleepTime & 0xFF);

    UTCTime* localStart = [UTCTime getLocalTimeFromUTC:sleepTime.mSleepStartHour minute:sleepTime.mSleepStartMinute second:0];
    UTCTime* localEnd = [UTCTime getLocalTimeFromUTC: sleepTime.mSleepEndHour
                                              minute: sleepTime.mSleepEndMinute
                                              second:0];
    
    sleepTime.mSleepStartHour = (Byte)localStart.mHours;
    sleepTime.mSleepStartMinute = (Byte)localStart.mMinutes;
    sleepTime.mSleepEndHour = (Byte)localEnd.mHours;
    sleepTime.mSleepEndMinute = (Byte)localEnd.mMinutes;

    return sleepTime;
}

-(int) updateConfig:(NSDictionary*)dicts
{
    int nUpdateParaNum = [super updateConfig:dicts];

    NSNumber* nTempValue = nil;

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_SCAN_INTERVAL];
    if (nTempValue != nil)
    {
        _nbScanInterval = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_SCAN_WINDOW];
    if (nTempValue != nil)
    {
        _nbScanWindow = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_ADV_TX_PWR];
    if (nTempValue != nil)
    {
        _nbAdvTxPower = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_ADV_INTERVAL];
    if (nTempValue != nil)
    {
        _nbAdvInterval = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_ALM_INTERVAL];
    if (nTempValue != nil)
    {
        _nbALmInterval = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:NEARBY_ALM_WINDOW];
    if (nTempValue != nil)
    {
        _nbALmDuration = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_ALM_FACTORY];
    if (nTempValue != nil)
    {
        _nbAlmFactory = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_ALM_DISTANCE];
    if (nTempValue != nil)
    {
        _nbAlmDistance = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_NEARBY_SLEEP_TIME];
    if (nTempValue != nil)
    {
        self->nbSleepTime = nTempValue;
        nUpdateParaNum++;
    }

    return nUpdateParaNum;
}

-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary* configDicts =  [super toDictionary];

    if (_nbScanInterval != nil)
    {
        [configDicts setObject:_nbScanInterval forKey:JSON_FIELD_NEARBY_SCAN_INTERVAL];
    }

    if (_nbScanWindow != nil)
    {
        [configDicts setObject:_nbScanWindow forKey:JSON_FIELD_NEARBY_SCAN_WINDOW];
    }

    if (_nbAdvTxPower != nil)
    {
        [configDicts setObject:_nbAdvTxPower forKey:JSON_FIELD_NEARBY_ADV_TX_PWR];
    }

    if (_nbAdvInterval != nil)
    {
        [configDicts setObject:_nbAdvInterval forKey:JSON_FIELD_NEARBY_ADV_INTERVAL];
    }

    if (_nbALmInterval != nil)
    {
        [configDicts setObject:_nbALmInterval forKey:JSON_FIELD_NEARBY_ALM_INTERVAL];
    }

    if (_nbALmDuration != nil)
    {
        [configDicts setObject:_nbALmDuration forKey:NEARBY_ALM_WINDOW];
    }

    if (_nbAlmFactory != nil)
    {
        [configDicts setObject:_nbAlmFactory forKey:JSON_FIELD_NEARBY_ALM_FACTORY];
    }

    if (_nbAlmDistance != nil)
    {
        [configDicts setObject:_nbAlmDistance forKey:JSON_FIELD_NEARBY_ALM_DISTANCE];
    }

    if (self->nbSleepTime != nil)
    {
        [configDicts setObject:self->nbSleepTime forKey:JSON_FIELD_NEARBY_SLEEP_TIME];
    }

    return configDicts;
}


@end
