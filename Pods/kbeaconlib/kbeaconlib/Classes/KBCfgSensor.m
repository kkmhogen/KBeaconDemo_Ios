//
//  KBCfgSensor.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/29.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBCfgSensor.h"
#import "KBException.h"

#define JSON_FIELD_TYPE_ENABLE_SENSOR "sensor"

@implementation KBCfgSensor

-(KBConfigType) cfgParaType
{
    return KBConfigTypeSensor;
}

-(void)setSensorType:(NSNumber*) sensorType
{
    int nTmpSensorType = [sensorType intValue];
    if (nTmpSensorType != 0
        && (nTmpSensorType & KBSensorTypeAcc) == 0
        && (nTmpSensorType & KBSensorTypeHumidity) == 0)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"sensor type invalid"];
    }
    else
    {
        _sensorType = sensorType;
    }
}

-(int) updateConfig:(NSDictionary*)dicts
{
    int nUpdateConfigNum = 0;
    
    NSNumber* tmpNumber = [dicts objectForKey:JSON_FIELD_SENSOR_TYPE];
    if (tmpNumber != nil)
    {
        _sensorType = tmpNumber;
        nUpdateConfigNum++;
    }
    
    tmpNumber = [dicts objectForKey:JSON_SENSOR_TYPE_HT_MEASURE_INTERVAL];
    if (tmpNumber != nil)
    {
        _sensorHtMeasureInterval = tmpNumber;
       nUpdateConfigNum++;
    }

    tmpNumber = [dicts objectForKey:JSON_SENSOR_TYPE_HT_TEMP_CHANGE_THD];
    if (tmpNumber != nil)
    {
       _sensorHtTempSaveThreshold = tmpNumber;
       nUpdateConfigNum++;
    }

    tmpNumber = [dicts objectForKey:JSON_SENSOR_TYPE_HT_HUMIDITY_CHANGE_THD];
    if (tmpNumber != nil)
    {
       _sensorHtHumiditySaveThreshold = tmpNumber;
       nUpdateConfigNum++;
    }

    return nUpdateConfigNum;
}

+(NSString*)getSensorTypeString:(NSNumber*) nSensorType
{
    NSString* strTypeDesc = @"";
    
    if (([nSensorType intValue] & KBSensorTypeAcc) > 0)
    {
        strTypeDesc = [NSString stringWithFormat:@"%@%@|", strTypeDesc, SENSOR_TYPE_ACC_POSITION];
    }
    
    if (([nSensorType intValue] & KBSensorTypeHumidity) > 0)
    {
        strTypeDesc = [NSString stringWithFormat:@"%@%@|", strTypeDesc, ENSOR_TYPE_HUMIDITY_2_TEMP];
    }
    
    if ([nSensorType intValue] == 0)
    {
        return @"none";
    }
    else
    {
        return strTypeDesc;
    }
}


-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary* configDicts = [[NSMutableDictionary alloc]initWithCapacity:2];
    
    if (_sensorType != nil)
    {
        [configDicts setObject:_sensorType forKey:JSON_FIELD_SENSOR_TYPE];
    }
    
    if (_sensorHtMeasureInterval != nil)
    {
        [configDicts setObject:_sensorHtMeasureInterval forKey:JSON_SENSOR_TYPE_HT_MEASURE_INTERVAL];
    }
    
    if (_sensorHtTempSaveThreshold != nil)
    {
        [configDicts setObject:_sensorHtTempSaveThreshold forKey:JSON_SENSOR_TYPE_HT_TEMP_CHANGE_THD];
    }
    
    if (_sensorHtHumiditySaveThreshold != nil)
    {
        [configDicts setObject:_sensorHtHumiditySaveThreshold forKey:JSON_SENSOR_TYPE_HT_HUMIDITY_CHANGE_THD];
    }
    
    return configDicts;
}

@end
