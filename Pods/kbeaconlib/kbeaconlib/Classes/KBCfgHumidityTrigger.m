//
//  KBCfgHumidityTrigger.m
//  KBeacon
//
//  Created by hogen on 2020/11/15.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBCfgHumidityTrigger.h"
#import "KBException.h"

@implementation KBCfgHumidityTrigger

-(void)setTriggerTemperatureAbove:(NSNumber*) triggerThd
{
    if ([triggerThd intValue] > 1000 || [triggerThd intValue] < -50)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"trigger adv mode invalid"];
    }
    
    _triggerTemperatureAbove = triggerThd;
}


-(void)setTriggerTemperatureBelow:(NSNumber*) triggerThd
{
    if ([triggerThd intValue]> 1000 || [triggerThd intValue] < -50)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"temperature below threshold is invalid"];
    }
    
    _triggerTemperatureBelow = triggerThd;
}

-(void)setTriggerHumidityAbove:(NSNumber*) triggerThd
{
    if ([triggerThd intValue]  > 100 || [triggerThd intValue]  < 0)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"humidity above threshold is invalid"];
    }
    
    _triggerHumidityAbove = triggerThd;
}

-(void)setTriggerHumidityBelow:(NSNumber*) triggerThd
{
    if ([triggerThd intValue]  > 100 || [triggerThd intValue]  < 0)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"humidity above threshold is invalid"];
    }

    _triggerHumidityAbove = triggerThd;
}

-(int) updateConfig:(NSDictionary*)dicts
{
    int nUpdateParaNum = [super updateConfig:dicts];
    NSNumber* nTempValue = nil;

    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_HUMIDITY_PARA_MASK];
    if (nTempValue != nil)
    {
        _triggerHtParaMask = nTempValue;
        nUpdateParaNum++;
    }
    
    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_TEMPERATURE_ABOVE];
    if (nTempValue != nil)
    {
        _triggerTemperatureAbove = nTempValue;
        nUpdateParaNum++;
    }
    
    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_TEMPERATURE_BELOW];
    if (nTempValue != nil)
    {
        _triggerTemperatureBelow = nTempValue;
        nUpdateParaNum++;
    }
    
    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_HUMIDITY_ABOVE];
    if (nTempValue != nil)
    {
        _triggerHumidityAbove = nTempValue;
        nUpdateParaNum++;
    }
    
    nTempValue = [dicts objectForKey:JSON_FIELD_TRIGGER_HUMIDITY_BELOW];
    if (nTempValue != nil)
    {
        _triggerHumidityBelow = nTempValue;
        nUpdateParaNum++;
    }
    
    return nUpdateParaNum;
}

-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary* configDicts =  [super toDictionary];

    if (_triggerHtParaMask != nil)
    {
        [configDicts setObject:_triggerHtParaMask forKey:JSON_FIELD_TRIGGER_HUMIDITY_PARA_MASK];
    }

    if (_triggerTemperatureAbove != nil)
    {
        [configDicts setObject:_triggerTemperatureAbove forKey:JSON_FIELD_TRIGGER_TEMPERATURE_ABOVE];
    }

    if (_triggerTemperatureBelow != nil)
    {
        [configDicts setObject:_triggerTemperatureBelow forKey:JSON_FIELD_TRIGGER_TEMPERATURE_BELOW];
    }

    if (_triggerHumidityAbove != nil)
    {
        [configDicts setObject:_triggerHumidityAbove forKey:JSON_FIELD_TRIGGER_HUMIDITY_ABOVE];
    }

    if (_triggerHumidityBelow != nil)
    {
        [configDicts setObject:_triggerHumidityBelow forKey:JSON_FIELD_TRIGGER_HUMIDITY_BELOW];
    }

    return configDicts;
}

@end
