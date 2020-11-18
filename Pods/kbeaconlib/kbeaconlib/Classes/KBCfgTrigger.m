//
//  KBCfgTrigger.m
//  KBeacon
//
//  Created by hogen on 2020/2/8.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBCfgTrigger.h"
#import "KBException.h"
#import "KBAdvPacketBase.h"


@implementation KBCfgTrigger

-(KBConfigType) cfgParaType
{
    return KBConfigTypeTrigger;
}

-(void)setTriggerType:(NSNumber*) triggerType
{
    _triggerType = triggerType;
}

-(void)setTriggerAction:(NSNumber*) triggerAction
{
    _triggerAction = triggerAction;
}

-(void)setTriggerPara:(NSNumber*) triggerPara
{
    _triggerPara = triggerPara;
}

-(void)setTriggerAdvMode:(NSNumber*) triggerAdvMode
{
    if ([triggerAdvMode intValue] == KBTriggerAdvOnlyMode
        || [triggerAdvMode intValue] == KBTriggerAdv2AliveMode
        || [triggerAdvMode intValue] == KBTriggerNoAdvMode)
    {
        _triggerAdvMode = triggerAdvMode;
    }
    else
    {
       @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"trigger adv mode invalid"];

    }
}

-(void)setTriggerAdvType:(NSNumber*) triggerAdvType
{
    int nTmpAdvType = [triggerAdvType intValue];
    if (nTmpAdvType == KBAdvTypeSensor
        || nTmpAdvType == KBAdvTypeEddyUID
        || nTmpAdvType == KBAdvTypeIBeacon
        || nTmpAdvType == KBAdvTypeEddyTLM
        || nTmpAdvType == KBAdvTypeEddyURL)
    {
        _triggerAdvType = triggerAdvType;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"advertisement type invalid"];
    }
}

-(void)setTriggerAdvTime:(NSNumber*) triggerAdvTime
{
    if ([triggerAdvTime intValue] >= 10 && [triggerAdvTime intValue] <= 7200) {
        _triggerAdvTime = triggerAdvTime;
    }
    else
    {
       @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"trigger adv time invalid"];

    }
}

-(void)setTriggerAdvInterval:(NSNumber*) triggerAdvInterval
{
    if ([triggerAdvInterval floatValue] >= 100.0 &&
        [triggerAdvInterval floatValue] <= 10000.0) {
        _triggerAdvInterval = triggerAdvInterval;
    }
    else
    {
       @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"trigger adv interval invalid"];

    }
}

-(int) updateConfig:(NSDictionary*)dicts
{
    int nUpdateParaNum = 0;
    NSNumber* nTempValue = nil;

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_TYPE];
    if (nTempValue != nil)
    {
        _triggerType = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_ACTION];
    if (nTempValue != nil)
    {
        _triggerAction = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_PARA];
    if (nTempValue != nil)
    {
        _triggerPara = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_ADV_MODE];
    if (nTempValue != nil)
    {
        _triggerAdvMode = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_ADV_TYPE];
    if (nTempValue != nil)
    {
        _triggerAdvType = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_ADV_TIME];
    if (nTempValue != nil)
    {
        _triggerAdvTime = nTempValue;
        nUpdateParaNum++;
    }

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_ADV_INTERVAL];
    if (nTempValue != nil)
    {
        _triggerAdvInterval = nTempValue;
        nUpdateParaNum++;
    }
    
    return nUpdateParaNum;
}


-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary* configDicts = [[NSMutableDictionary alloc]initWithCapacity:2];
    
    if (_triggerType != nil)
    {
        [configDicts setObject:_triggerType forKey:JSON_FIELD_TRIGGER_TYPE];
    }

    if (_triggerAction != nil)
    {
        [configDicts setObject:_triggerAction forKey:JSON_FIELD_TRIGGER_ACTION];
    }

    if (_triggerPara != nil)
    {
        [configDicts setObject:_triggerPara forKey:JSON_FIELD_TRIGGER_PARA];
    }

    if (_triggerAdvMode != nil)
    {
        [configDicts setObject:_triggerAdvMode forKey:JSON_FIELD_TRIGGER_ADV_MODE];
    }

    if (_triggerAdvType != nil)
    {
        [configDicts setObject:_triggerAdvType forKey:JSON_FIELD_TRIGGER_ADV_TYPE];
    }

    if (_triggerAdvTime != nil)
    {
        [configDicts setObject:_triggerAdvTime forKey:JSON_FIELD_TRIGGER_ADV_TIME];
    }

    if (_triggerAdvInterval != nil)
    {
        [configDicts setObject:_triggerAdvInterval forKey:JSON_FIELD_TRIGGER_ADV_INTERVAL];
    }
    
    return configDicts;
}
@end
