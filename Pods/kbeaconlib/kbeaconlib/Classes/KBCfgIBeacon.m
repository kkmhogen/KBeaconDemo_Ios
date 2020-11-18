//
//  KBIBeaconCfg.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/28.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBCfgIBeacon.h"
#import "KBException.h"

@implementation KBCfgIBeacon

-(KBConfigType) cfgParaType
{
    return KBConfigTypeIBeacon;
}

-(void)setMajorID:(NSNumber*) majorID
{
    if ([majorID intValue] >= 0 && [majorID intValue] <= 65535)
    {
        _majorID = majorID;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"iBeacon majorID invalid"];
    }
}

-(void)setMinorID:(NSNumber*) minorID
{
    if ([minorID intValue] >= 0 && [minorID intValue] <= 65535)
    {
        _minorID = minorID;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"iBeacon minorID invalid"];
    }
}

-(void)setUuid:(NSString*) uuid
{
    if ([KBUtility isUUIDString:uuid])
    {
        _uuid = uuid;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"iBeacon uuid invalid"];
    }
}

-(int) updateConfig:(NSDictionary*)dicts
{
    int nUpdateParaNum = 0;
    
    NSString* strTempValue = [dicts objectForKey:JSON_FIELD_IBEACON_UUID];
    if (strTempValue != nil)
    {
        _uuid = strTempValue;
        nUpdateParaNum++;
    }
    
    NSNumber* nMjaorID = [dicts objectForKey:JSON_FIELD_IBEACON_MAJORID];
    if (nMjaorID != nil)
    {
        _majorID = nMjaorID;
        nUpdateParaNum++;
    }
    
    NSNumber* nMinorID = [dicts objectForKey:JSON_FIELD_IBEACON_MINORID];
    if (nMinorID != nil)
    {
        _minorID = nMinorID;
        nUpdateParaNum++;
    }
    
    return nUpdateParaNum;
}

-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary*cfgDicts = [[NSMutableDictionary alloc]init];

    if (_uuid != nil)
    {
        [cfgDicts setObject:_uuid forKey:JSON_FIELD_IBEACON_UUID];
    }
    
    if (_majorID != nil)
    {
        [cfgDicts setObject:_majorID forKey:JSON_FIELD_IBEACON_MAJORID];
    }
    
    if (_minorID != nil)
    {
        [cfgDicts setObject:_minorID forKey:JSON_FIELD_IBEACON_MINORID];
    }
    
    return cfgDicts;
    
}


@end
