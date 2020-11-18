//
//  KBCfgSensor.h
//  KBeaconConfig
//
//  Created by kkm on 2019/7/29.
//  Copyright © 2019 kkm. All rights reserved.
//

#import <KBCfgBase.h>

NS_ASSUME_NONNULL_BEGIN

#define JSON_FIELD_SENSOR_TYPE @"sensor"

#define SENSOR_TYPE_ACC_POSITION @"Acceleration"
#define ENSOR_TYPE_HUMIDITY_2_TEMP @"Humidity"

#define JSON_SENSOR_TYPE_HT_MEASURE_INTERVAL @"msItvl"
#define JSON_SENSOR_TYPE_HT_TEMP_CHANGE_THD @"tsThd"
#define JSON_SENSOR_TYPE_HT_HUMIDITY_CHANGE_THD @"hsThd"


//beacon av type
typedef NS_ENUM(NSInteger, KBSensorType)
{
    KBSensorTypeDisable = 0x0,
    KBSensorTypeAcc = 0x1,
    KBSensorTypeHumidity = 0x2
} ;

@interface KBCfgSensor : KBCfgBase

//sensor type about KSensor
@property (strong, nonatomic) NSNumber* sensorType;

//HT measure interval
@property (strong, nonatomic) NSNumber* sensorHtMeasureInterval;

//Temperature change save interval
@property (strong, nonatomic) NSNumber* sensorHtTempSaveThreshold;

//humidity change save interval
@property (strong, nonatomic) NSNumber* sensorHtHumiditySaveThreshold;

-(int) updateConfig:(NSDictionary*)dicts;

-(NSMutableDictionary*) toDictionary;

+(NSString*)getSensorTypeString:(NSNumber*) nSensorType;

@end

NS_ASSUME_NONNULL_END
