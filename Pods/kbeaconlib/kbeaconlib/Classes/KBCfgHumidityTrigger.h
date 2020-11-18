//
//  KBCfgHumidityTrigger.h
//  KBeacon
//
//  Created by hogen on 2020/11/15.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <KBCfgTrigger.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KBTriggerHTMask)
{
    KBTriggerHTParaMaskTemperatureAbove = 0x1,
    KBTriggerHTParaMaskTemperatureBelow = 0x2,
    KBTriggerHTParaMaskHumidityAbove = 0x4,
    KBTriggerHTParaMaskHumidityBelow = 0x8
} ;

typedef NS_ENUM(NSInteger, KBTriggerHTCondition)
{
    KBTriggerHTConditionDefaultTemperatureAbove = 60,
    KBTriggerHTConditionDefaultTemperatureBelow = -10,
    KBTriggerHTConditionDefaultHumidityAbove = 80,
    KBTriggerHTConditionDefaultHumidityBelow = 20
} ;

#define JSON_FIELD_TRIGGER_HUMIDITY_PARA_MASK @"htMsk"
#define JSON_FIELD_TRIGGER_TEMPERATURE_ABOVE @"tpAbv"
#define JSON_FIELD_TRIGGER_TEMPERATURE_BELOW @"tpBlw"
#define JSON_FIELD_TRIGGER_HUMIDITY_ABOVE @"htAbv"
#define JSON_FIELD_TRIGGER_HUMIDITY_BELOW @"htBlw"

@interface KBCfgHumidityTrigger : KBCfgTrigger


@property (strong, nonatomic) NSNumber* triggerHtParaMask;

@property (strong, nonatomic) NSNumber* triggerTemperatureAbove;

@property (strong, nonatomic) NSNumber* triggerTemperatureBelow;

@property (strong, nonatomic) NSNumber* triggerHumidityAbove;

@property (strong, nonatomic) NSNumber* triggerHumidityBelow;


@end

NS_ASSUME_NONNULL_END
