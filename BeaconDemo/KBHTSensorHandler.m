//
//  KBHTSensorOpteration.m
//  kbeaconlib_Example
//
//  Created by hogen on 2020/11/17.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBHTSensorHandler.h"
#import "KBHumidityNotifyData.h"
#import "KBCfgHumidityTrigger.h"
#import <KBCfgSensor.h>

@implementation KBHTSensorHandler

-(NSString*) localTimeFromUTCSeconds:(long)utcSecond
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:utcSecond];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}

//modify humidity sensor measure interval and logger threshold
-(void)configSensorMeasurePara
{
    KBCfgSensor* humiditySensor = [[KBCfgSensor alloc]init];
    
    NSMutableArray* cfgList = [[NSMutableArray alloc]init];
    
    //the humidity unit is 0.1%
    humiditySensor.sensorHtHumiditySaveThreshold = [NSNumber numberWithInt:50];
    
    //the temperature unit is 0.1
    humiditySensor.sensorHtHumiditySaveThreshold = [NSNumber numberWithInt:5];
    
    //measure interval, unit is sec
    humiditySensor.sensorHtMeasureInterval = [NSNumber numberWithInt:3];
    
    [cfgList addObject:humiditySensor];
    
    //modify paramaters
    [self.mBeacon modifyConfig:cfgList callback:^(BOOL bConfigSuccess, NSError * _Nonnull error) {
        if (bConfigSuccess)
        {
            NSLog(@"modify humidity sensor paramaters success");
        }
        else
        {
            NSLog(@"modify humidity sensor paramaters failed");
        }
    }];
}

- (void)onNotifyDataReceived:(nonnull KBeacon *)beacon type:(int)dataType data:(nonnull KBNotifyDataBase *)data
{
    KBHumidityNotifyData* notifyData = (KBHumidityNotifyData*)data;

    float humidity = [notifyData.humidity floatValue];
    float temperature = [notifyData.temperature floatValue];
    long nEventTime = [notifyData.eventUTCTime longValue];

    NSString* strEvtUtcTime = [self localTimeFromUTCSeconds:nEventTime];
    NSLog(@"utc:%@, temperature:%0.2f, humidity:%0.2f",
          strEvtUtcTime, temperature, humidity);
}

//Please make sure the app does not enable any trigger's advertisement mode to KBTriggerAdvOnlyMode
//If the app set some trigger advertisement mode to KBTriggerAdvOnlyMode, then the device only start advertisement when trigger event happened.
//when this function enabled, then the device will include the realtime temperature and humidity data in advertisement
-(void)enableTHRealtimeDataToAdv
{
    KBCfgCommon* oldCommonCfg = (KBCfgCommon*)[self.mBeacon getConfigruationByType:KBConfigTypeCommon];
    KBCfgSensor* oldSensorCfg = (KBCfgSensor*)[self.mBeacon getConfigruationByType:KBConfigTypeSensor];
    

   @try{
       //disable temperature trigger, if you enable other trigger, for example, motion trigger, button trigger, please set the trigger adv mode to always adv mode
       //or disable that trigger
       KBCfgHumidityTrigger* thTriggerPara = [[KBCfgHumidityTrigger alloc]init];
       thTriggerPara.triggerType = [NSNumber numberWithInt:KBTriggerTypeHumidity];
       thTriggerPara.triggerAction = [NSNumber numberWithInt:KBTriggerActionOff];
       [self.mBeacon modifyTriggerConfig:thTriggerPara callback:^(BOOL bConfigSuccess, NSError * _Nonnull error)
        {
           if (!bConfigSuccess)
           {
               NSLog(@"disable humidity trigger failed");
               return;
           }
           
           //enable ksensor advertisement
           NSMutableArray* newCfg = [[NSMutableArray alloc]init];
           if (([oldCommonCfg.advType intValue] & KBAdvTypeSensor) == 0) {
               KBCfgCommon* newCommonCfg = [[KBCfgCommon alloc]init];
               newCommonCfg.advType= [NSNumber numberWithInt: KBAdvTypeSensor];
               [newCfg addObject:newCommonCfg];
           }

           //enable temperature and humidity
           NSNumber* nOldSensorType = oldSensorCfg.sensorType;
           if (nOldSensorType == nil || ([nOldSensorType intValue] & KBSensorTypeHumidity) == 0)
           {
               KBCfgSensor* sensorCfg = [[KBCfgSensor alloc]init];
               sensorCfg.sensorType = [NSNumber numberWithInt:KBSensorTypeHumidity | [nOldSensorType intValue] ];
               [newCfg addObject:sensorCfg];
           }

           [self.mBeacon modifyConfig:newCfg callback:^(BOOL bConfigSuccess, NSError * _Nullable error) {
               if (bConfigSuccess)
               {
                   NSLog(@"enable humidity data report to app and adv success");
               }
               else
               {
                   NSLog(@"enable humidity data report to adv failed");
               }
           }];
       }];
   }
   @catch (KBException *exception)
   {
       NSLog(@"enable humidity advertisement failed");
       return;
   }
}


//please make sure the app does not enable temperature&humidity trigger
//If the app enable the trigger, the device only report the sensor data to app when trigger event happened.
//After enable realtime data to app, then the device will periodically send the temperature and humidity data to app whether it was changed or not.
-(void)enableTHRealtimeDataToApp
{
    //turn off trigger
    @try {
       //make sure the trigger was turn off
       KBCfgHumidityTrigger* thTriggerPara = [[KBCfgHumidityTrigger alloc]init];
       thTriggerPara.triggerType = [NSNumber numberWithInt: KBTriggerTypeHumidity];
       thTriggerPara.triggerAction = [NSNumber numberWithInt: KBTriggerActionOff];

       [self.mBeacon modifyTriggerConfig:thTriggerPara callback:^(BOOL bConfigSuccess, NSError * _Nullable error) {
           if (!bConfigSuccess)
           {
               NSLog(@"turn off TH trigger failed");
               return;
           }

           if (![self.mBeacon isSensorDataSubscribe:KBHumidityNotifyData.class])
           {
               [self.mBeacon subscribeSensorDataNotify:KBHumidityNotifyData.class delegate:self callback:^(BOOL bConfigSuccess, NSError * _Nullable error) {
                       if (bConfigSuccess) {
                           NSLog(@"subscribe temperature and humidity data success");
                       } else {
                           NSLog(@"subscribe temperature and humidity data failed");
                       }
               }];
           }
       }];
    }
    @catch (KBException *exception)
    {
        NSLog(@"enable humidity advertisement failed");
        return;
    }
}

//The device will start broadcasting when temperature&humidity trigger event happened
//for example, the humidity > 70% or temperature < 10 or temperature > 50
-(void)enableTHTriggerEvtRpt2Adv
{
    KBCfgHumidityTrigger* thTriggerPara = [[KBCfgHumidityTrigger alloc]init];

   @try {
       //set trigger type
       thTriggerPara.triggerType = [NSNumber numberWithInt: KBTriggerTypeHumidity];

       //set trigger advertisement enable
       thTriggerPara.triggerAction = [NSNumber numberWithInt: KBTriggerActionAdv];

       //set trigger adv mode to adv only on trigger
       thTriggerPara.triggerAdvMode = [NSNumber numberWithInt:KBTriggerAdvOnlyMode];

       //set trigger condition
       thTriggerPara.triggerHtParaMask = [NSNumber numberWithInt:KBTriggerHTParaMaskTemperatureAbove
               | KBTriggerHTParaMaskTemperatureBelow
               | KBTriggerHTParaMaskHumidityAbove];
       thTriggerPara.triggerTemperatureAbove = [NSNumber numberWithInt: 50];
       thTriggerPara.triggerTemperatureBelow = [NSNumber numberWithInt:-10];
       thTriggerPara.triggerHumidityAbove = [NSNumber numberWithInt:70];

       //set trigger adv type
       thTriggerPara.triggerAdvType = [NSNumber numberWithInt:KBAdvTypeSensor];

       //set trigger adv duration to 20 seconds
       thTriggerPara.triggerAdvTime = [NSNumber numberWithInt: 20];

       //set the trigger adv interval to 500ms
       thTriggerPara.triggerAdvInterval = [NSNumber numberWithFloat:500.0f];
       
       [self.mBeacon modifyTriggerConfig:thTriggerPara callback:^(BOOL bConfigSuccess, NSError * _Nullable error) {
           if (bConfigSuccess) {
               NSLog(@"enable temp&humidity trigger event to adv success");
           } else {
               NSLog(@"enable temp&humidity trigger error:%ld", (long)error.code);
           }
       }];
   }
    @catch (KBException *exception)
    {
        NSLog(@"enable humidity advertisement failed");
        return;
    }
}

//the device will send event to app when temperature&humidity trigger event happened
//for example, the humidity > 50%
//the app must subscribe the notification event if it want receive the event
-(void) enableTHTriggerEvtRpt2App
{

   @try
    {
       KBCfgHumidityTrigger* thTriggerPara = [[KBCfgHumidityTrigger alloc]init];

       //set trigger type
       thTriggerPara.triggerType = [NSNumber numberWithInt: KBTriggerTypeHumidity];

       //set trigger event that report to app
       thTriggerPara.triggerAction = [NSNumber numberWithInt:KBTriggerActionRptApp];

       //set trigger condition
       thTriggerPara.triggerHtParaMask = [NSNumber numberWithInt: KBTriggerHTParaMaskHumidityAbove];
       thTriggerPara.triggerHumidityAbove = [NSNumber numberWithInt:70];

       [self.mBeacon modifyTriggerConfig:thTriggerPara callback:^(BOOL bConfigSuccess, NSError * _Nullable error)
       {
           if (!bConfigSuccess) {
               NSLog(@"enable temp&humidity trigger event to app failed");
               return;
           }

           //subscribe humidity notify
           if (![self.mBeacon isSensorDataSubscribe:KBHumidityNotifyData.class])
           {
               [self.mBeacon subscribeSensorDataNotify:KBHumidityNotifyData.class delegate:self callback:^(BOOL bConfigSuccess, NSError * _Nullable error) {
                       if (bConfigSuccess) {
                           NSLog(@"subscribe temperature and humidity data success");
                       } else {
                           NSLog(@"subscribe temperature and humidity data failed");
                       }
               }];
           }
       }];
    }
    @catch (KBException *exception)
    {
        NSLog(@"enable humidity advertisement failed");
        return;
    }
}


@end
