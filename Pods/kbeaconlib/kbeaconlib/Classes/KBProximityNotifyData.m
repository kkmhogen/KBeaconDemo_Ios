//
//  KBProximityNotifyData.m
//  KBsocialAlarm
//
//  Created by hogen on 2020/8/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBProximityNotifyData.h"
#import "KBUtility.h"
#import "KBeacon.h"

#define DEFAULT_MESSAGE_LEN 15

@implementation KBProximityNotifyData

-(NSNumber*) getSensorDataType
{
    return [NSNumber numberWithInt: KBNotifyDataTypeProxmity];
}


-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf
{
    int nIndex = 1;
    const Byte* pRspData = [sensorDataNtf bytes];
    if (sensorDataNtf == nil || sensorDataNtf.length < DEFAULT_MESSAGE_LEN)
    {
        return;
    }

    //nearby utc time
    _utcTime = [NSNumber numberWithLong: htonl(*(uint32_t*)&pRspData[nIndex])];
    nIndex += 4;

    //mac address;
    Byte byMacAddress[4];
    byMacAddress[0] = pRspData[nIndex++];
    byMacAddress[1] = pRspData[nIndex++];
    byMacAddress[2] = pRspData[nIndex++];
    byMacAddress[3] = pRspData[nIndex++];
    NSString* strMacPrefex = [beacon.mac substringToIndex:6];
    NSData* pDMacTail = [[NSData alloc]initWithBytes:(void*)byMacAddress length:4];
    NSString* strMacTail = [[KBUtility bytesToHexString:pDMacTail] uppercaseString];
    if (strMacTail != nil)
    {
        _mac = [NSString stringWithFormat:@"%@:%@:%@:%@:%@",
            strMacPrefex,
            [strMacTail substringWithRange:(NSRange){0,2}],
            [strMacTail substringWithRange:(NSRange){2,2}],
            [strMacTail substringWithRange:(NSRange){4,2}],
            [strMacTail substringWithRange:(NSRange){6,2}]];
    }

    //major id
    _majorID = [NSNumber numberWithInt: htons(*(uint16_t*)&pRspData[nIndex])];
    nIndex += 2;

    //minor id
    _minorID = [NSNumber numberWithInt: htons(*(uint16_t*)&pRspData[nIndex])];
    nIndex += 2;

    //nearby time
    _nearbyTime = [NSNumber numberWithInt: pRspData[nIndex++]];

    //distance
    _nearbyDistance = [NSNumber numberWithInt: pRspData[nIndex]];
}

@end
