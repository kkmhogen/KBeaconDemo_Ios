//
//  KBCfgCommon.m
//  KBeaconConfig
//
//  Created by hogen on 2019/9/10.
//  Copyright © 2019 hogen. All rights reserved.
//

#import "KBCfgCommon.h"
#import "KBAdvPacketBase.h"
#import "KBException.h"

@implementation KBCfgCommon

- (id)init
{
    self = [super init];
    return self;
}

-(KBConfigType) cfgParaType
{
    return KBConfigTypeCommon;
}

-(void)setTlmAdvInterval:(NSNumber*)tlmAdvInterval
{
    if ([tlmAdvInterval intValue] >= MIN_TLM_INTERVAL
        && [tlmAdvInterval intValue] <= MAX_TLM_INTERVAL)
    {
        _tlmAdvInterval = tlmAdvInterval;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"TLM interval invalid"];
    }
}

-(void)setTxPower:(NSNumber*) txPower
{
    if ([txPower intValue] > 5 || [txPower intValue] < 40)
    {
        _txPower = txPower;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"TX power invalid"];
    }
}

-(void)setRefPower1Meters:(NSNumber*) refPower1Meters
{
    if ([refPower1Meters intValue] < -10
        && [refPower1Meters intValue] > -100)
    {
        _refPower1Meters = refPower1Meters;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"referance power invalid"];
    }
}

-(void)setAdvPeriod:(NSNumber*) advPeriod
{
    if (([advPeriod intValue] <= 10000 && [advPeriod intValue] >= 100)
        || advPeriod == 0)
    {
        _advPeriod = advPeriod;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"advertisement period invalid"];
    }
}

-(void)setPassword:(NSString*) password
{
    if (password.length >= 8 && password.length <= 16)
    {
        _password = password;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"password length invalid"];
    }
}

-(NSNumber*)advConnectable
{
    return [NSNumber numberWithInt:[_advFlags intValue] & KBAdvFlagConnectable];
}

-(NSNumber*)autoAdvAfterPowerOn
{
    return [NSNumber numberWithInt:[_advFlags intValue] & KBAdvFlagAutoPowerOn];
}

-(void)setAdvConnectable:(NSNumber *)advConnectFlag
{
    if (advConnectFlag != nil)
    {
        int nAdvFlags = 0;
        if (_advFlags != nil)
        {
            nAdvFlags = [_advFlags intValue];
        }
        
        if ([advConnectFlag intValue] > 0)
        {
            nAdvFlags = (nAdvFlags | KBAdvFlagConnectable);
        }
        else
        {
            nAdvFlags = (nAdvFlags & (~KBAdvFlagConnectable));
        }
        
        _advFlags = [NSNumber numberWithInt:nAdvFlags];
    }
}

-(void)setAutoAdvAfterPowerOn:(NSNumber *)autoPowerOnFlags
{
    if (autoPowerOnFlags != nil)
    {
        int nAdvFlags = 0;
        if (_advFlags != nil)
        {
            nAdvFlags = [_advFlags intValue];
        }
        
        if ([autoPowerOnFlags intValue] > 0)
        {
            nAdvFlags = (nAdvFlags | KBAdvFlagAutoPowerOn);
        }
        else
        {
            nAdvFlags = (nAdvFlags & (~KBAdvFlagAutoPowerOn));
        }
        
        _advFlags = [NSNumber numberWithInt:nAdvFlags];
    }
}

-(void)setAdvFlags:(NSNumber *)advFlags
{
    _advFlags = advFlags;
}

-(void)setName:(NSString*) name
{
    if (name.length <= MAX_NAME_LENGTH)
    {
        _name = name;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"device name length invalid"];
    }
}

-(void)setAdvType:(NSNumber*) advType
{
    int nTmpAdvType = [advType intValue];
    if ((nTmpAdvType & KBAdvTypeSensor) == 0
        && (nTmpAdvType & KBAdvTypeEddyUID) == 0
        && (nTmpAdvType & KBAdvTypeIBeacon) == 0
        && (nTmpAdvType & KBAdvTypeEddyTLM) == 0
        && (nTmpAdvType & KBAdvTypeEddyURL) == 0)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"advertisement type invalid"];
    }
    else
    {
        _advType = advType;
    }
}

-(int) updateConfig:(NSDictionary*)dicts
{
    NSString* strTempValue;
    NSNumber* nTmpNumberValue;
    int nUpdateParaNum = 0;
    
    //dev name
    strTempValue = [dicts objectForKey:JSON_FIELD_DEV_NAME];
    if (strTempValue != nil)
    {
        _name = strTempValue;
        nUpdateParaNum++;
    }
    
    //model name
    strTempValue = [dicts objectForKey:JSON_FIELD_BEACON_MODLE];
    if (strTempValue != nil)
    {
        _model = strTempValue;
        nUpdateParaNum++;
    }
    
    //version
    strTempValue = [dicts objectForKey:JSON_FIELD_BEACON_VER];
    if (strTempValue != nil)
    {
        _version = strTempValue;
        nUpdateParaNum++;
    }
    
    //hardware version
    strTempValue = [dicts objectForKey:JSON_FIELD_BEACON_HVER];
    if (strTempValue != nil)
    {
        _hversion = strTempValue;
        nUpdateParaNum++;
    }
    
    //max tx power
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_MAX_TX_PWR];
    if (nTmpNumberValue != nil)
    {
        _maxTxPower = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //min tx power
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_MIN_TX_PWR];
    if (nTmpNumberValue != nil)
    {
        _minTxPower = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //capibility
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_BASIC_CAPIBILITY];
    if (nTmpNumberValue != nil)
    {
        _basicCapibility = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //capibility
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_TRIG_CAPIBILITY];
    if (nTmpNumberValue != nil)
    {
        _trigCapibility = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //adv flag
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_ADV_FLAG];
    if (nTmpNumberValue != nil)
    {
        _advFlags = nTmpNumberValue;
        
        nUpdateParaNum++;

    }
    
    //adv period
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_ADV_PERIOD];
    if (nTmpNumberValue != nil)
    {
        _advPeriod = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //tx power
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_TX_PWR];
    if (nTmpNumberValue != nil)
    {
        if ([nTmpNumberValue intValue] >= [_minTxPower intValue]
            && [nTmpNumberValue intValue] <= [_maxTxPower intValue])
        {
            _txPower = nTmpNumberValue;
            nUpdateParaNum++;
        }
    }
    
    //measure power
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_MEA_PWR];
    if (nTmpNumberValue != nil)
    {
        _refPower1Meters = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //beacon type
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_BEACON_TYPE];
    if (nTmpNumberValue != nil)
    {
        _advType = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    //tlm interval
    nTmpNumberValue = [dicts objectForKey:JSON_FIELD_TLM_ADV_INTERVAL];
    if (nTmpNumberValue != nil)
    {
        _tlmAdvInterval = nTmpNumberValue;
        nUpdateParaNum++;
    }
    
    
    return nUpdateParaNum;
}



-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary* configDicts = [[NSMutableDictionary alloc]initWithCapacity:10];
    
    if (_advType != nil)
    {
        [configDicts setObject:_advType forKey:JSON_FIELD_BEACON_TYPE];
    }
    
    if (_name != nil)
    {
        [configDicts setObject:_name forKey:JSON_FIELD_DEV_NAME];
    }
    
    if (_advPeriod != nil)
    {
        [configDicts setObject:_advPeriod forKey:JSON_FIELD_ADV_PERIOD];
    }
    
    if (_tlmAdvInterval != nil)
    {
        [configDicts setObject:_tlmAdvInterval forKey:JSON_FIELD_TLM_ADV_INTERVAL];
    }
    
    if (_txPower != nil)
    {
        [configDicts setObject:_txPower forKey:JSON_FIELD_TX_PWR];
    }
    
    if (_refPower1Meters != nil)
    {
        [configDicts setObject:_refPower1Meters forKey:JSON_FIELD_MEA_PWR];
    }
    
    //adv flags
    if (_advFlags)
    {
        [configDicts setObject:_advFlags forKey:JSON_FIELD_ADV_FLAG];
    }
    
    //password
    if (_password != nil && _password.length >= 8 && _password.length <= 16)
    {
        [configDicts setObject:_password forKey:JSON_FIELD_PWD];
    }
    
    return configDicts;
}

-(NSString*) advTypeString
{
    return [KBCfgCommon getAdvTypeString:self.advType];
}


+(NSString*) getAdvTypeString:(NSNumber*)nAdvType
{
    int advType = [nAdvType intValue];
    NSMutableArray* nsBeaconTypeArray = [[NSMutableArray alloc]init];
    
    if (advType & KBAdvTypeIBeacon)
    {
        [nsBeaconTypeArray addObject: KBAdvTypeIBeaconString];
    }
    if (advType & KBAdvTypeEddyURL)
    {
        [nsBeaconTypeArray addObject: KBAdvTypeEddyURLString];
    }
    if (advType & KBAdvTypeEddyUID)
    {
        [nsBeaconTypeArray addObject: KBAdvTypeEddyUIDString];
    }
    if (advType & KBAdvTypeEddyTLM)
    {
        [nsBeaconTypeArray addObject: KBAdvTypeEddyTLMString];
    }
    if (advType & KBAdvTypeSensor)
    {
        [nsBeaconTypeArray addObject: KBAdvTypeSensorString];
    }
    
    NSString* strBeaconString = [[NSString alloc]init];
    strBeaconString = (nsBeaconTypeArray.count > 0) ? nsBeaconTypeArray[0] : @"null";
    if (nsBeaconTypeArray.count > 1)
    {
        for (int i = 1; i < nsBeaconTypeArray.count; i++)
        {
            strBeaconString = [strBeaconString stringByAppendingFormat:@"|%@", nsBeaconTypeArray[i]];
        }
    }
    
    return strBeaconString;
}

//is the device support iBeacon
-(BOOL) isSupportIBeacon
{
    int nAdvCapibility = ([self.basicCapibility intValue] >> 8);
    return ((nAdvCapibility & KBAdvTypeIBeacon) > 0);
}

//is the device support URL
-(BOOL) isSupportEddyURL
{
    int nAdvCapibility = ([self.basicCapibility intValue] >> 8);
    return ((nAdvCapibility & KBAdvTypeEddyURL) > 0);
}

//is the device support TLM
-(BOOL)isSupportEddyTLM
{
    int nAdvCapibility = ([self.basicCapibility intValue] >> 8);
    return ((nAdvCapibility & KBAdvTypeEddyTLM) > 0);
}

//is the device support UID
-(BOOL) isSupportEddyUID
{
    int nAdvCapibility = ([self.basicCapibility intValue] >> 8);
    return ((nAdvCapibility & KBAdvTypeEddyUID) > 0);
}

//support kb sensor
-(BOOL) isSupportKBSensor
{
    int nAdvCapibility = ([self.basicCapibility intValue] >> 8);
    return ((nAdvCapibility & KBAdvTypeSensor) > 0);
}

//is support button
-(BOOL) isSupportButton
{
    return (([self.basicCapibility intValue] & 0x1) > 0);
}

//is support beep
-(BOOL) isSupportBeep
{
    return (([self.basicCapibility intValue] & 0x2) > 0);
}

//is support acc sensor
-(BOOL) isSupportAccSensor
{
    return (([self.basicCapibility intValue] & 0x4) > 0);
}

//is support humidity sensor
-(BOOL) isSupportHumiditySensor
{
    return (([self.basicCapibility intValue] & 0x8) > 0);
}


-(NSArray*) getSupportedSensorArray
{
    NSMutableArray* mutableArray = [[NSMutableArray alloc]init];
    
    if ([self isSupportAccSensor])
    {
        [mutableArray addObject:[NSNumber numberWithInt:KB_CAPIBILITY_ACC]];
    }
    
    if ([self isSupportAccSensor])
    {
        [mutableArray addObject:[NSNumber numberWithInt:KB_CAPIBILITY_HUMIDITY]];
    }

    return mutableArray;
}

/*
+(NSArray*) getBeaconStringByType:(NSNumber*)beaconCfgType
{
    int advType = [beaconCfgType intValue];
    NSMutableArray* nsBeaconTypeArray = [[NSMutableArray alloc]init];
    
    if (advType & KBAdvTypeIBeacon)
    {
        [nsBeaconTypeArray addObject: JSON_FIELD_TYPE_IBEACON];
    }
    else if (advType == KBAdvTypeEddyURL)
    {
        [nsBeaconTypeArray addObject: JSON_FIELD_TYPE_EDD_URL];
    }
    else if (advType == KBAdvTypeEddyUID)
    {
        [nsBeaconTypeArray addObject: JSON_FIELD_TYPE_EDD_UID];
    }
    else if (advType == KBAdvTypeEddyTLM)
    {
        [nsBeaconTypeArray addObject: JSON_FIELD_TYPE_EDD_TLM];
    }
    else if (advType == KBAdvTypeSensor)
    {
        [nsBeaconTypeArray addObject: JSON_FIELD_TYPE_EDD_TLM_EXT];
    }
    
    return nsBeaconTypeArray;
}

+(NSNumber*)getBeaconTypeByString:(NSArray*) strBeaconTypeArray
{
    int advType = 0;
    
    for (NSString* strBeaconType in strBeaconTypeArray)
    {
        if ([JSON_FIELD_TYPE_IBEACON isEqualToString:strBeaconType])
        {
            advType =  advType | KBAdvTypeIBeacon;
        }
        else if([JSON_FIELD_TYPE_EDD_TLM isEqualToString:strBeaconType])
        {
            advType =  advType | KBAdvTypeEddyTLM;
        }
        else if([JSON_FIELD_TYPE_EDD_URL isEqualToString:strBeaconType])
        {
            advType =  advType | KBAdvTypeEddyURL;
        }
        else if([JSON_FIELD_TYPE_EDD_UID isEqualToString:strBeaconType])
        {
            advType =  advType | KBAdvTypeEddyUID;
        }
        else if([JSON_FIELD_TYPE_EDD_TLM_EXT isEqualToString:strBeaconType])
        {
            advType =  advType | KBAdvTypeSensor;
        }
    }
    
    return [NSNumber numberWithInt:advType];
}
*/
@end
