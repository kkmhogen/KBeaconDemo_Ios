//
//  KBHumidityNotifyData.m
//  KBeacon
//
//  Created by hogen on 2020/11/15.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBHumidityNotifyData.h"
#import "KBUtility.h"

#define DEFAULT_MESSAGE_LEN 9

@implementation KBHumidityNotifyData

-(NSNumber*) getSensorDataType
{
    return  [NSNumber numberWithInt: KBNotifyDataTypeHumidity];
}

-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf
{
    int nIndex = 1;
    const Byte* pRspData = [sensorDataNtf bytes];
    if (sensorDataNtf == nil || sensorDataNtf.length < DEFAULT_MESSAGE_LEN)
    {
        return;
    }

    //event utc time
    _eventUTCTime = [NSNumber numberWithLong: htonl(*(uint32_t*)&pRspData[nIndex])];
    nIndex += 4;

    //temperature
    float fTemperature = [KBUtility signedBytes2Float:pRspData[nIndex] second:pRspData[nIndex+1]];
    _temperature = [NSNumber numberWithFloat:fTemperature];
    nIndex += 2;

    //humidity
    float fHumidity = [KBUtility signedBytes2Float:pRspData[nIndex] second:pRspData[nIndex+1]];
    _humidity = [NSNumber numberWithFloat:fHumidity];
    nIndex += 2;
}

@end
