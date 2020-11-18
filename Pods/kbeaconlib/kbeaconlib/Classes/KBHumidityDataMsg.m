//
//  KBHumidityDataMsg.m
//  KBeacon
//
//  Created by hogen on 2020/11/3.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBHumidityDataMsg.h"
#import "UTCTime.h"
#import "KBHumidityRecord.h"


@implementation ReadHTSensorInfoRsp
@end

@implementation ReadHTSensorDataRsp
@end

@implementation KBHumidityDataMsg
{
    long utcSecondsOffset;
}

-(NSInteger) getSensorDataType
{
    return KBSensorDataTypeHumidity;
}


-(NSData*) makeReadSensorDataReq:(NSUInteger)nReadRcdNo order:(NSUInteger)nReadOrder readNumber:( NSUInteger) nMaxRecordNum
{
    Byte byMsgReq[7];
    NSUInteger nIndex = 0;

    //read pos
    byMsgReq[nIndex++] = (Byte)((nReadRcdNo >> 24) & 0xFF);
    byMsgReq[nIndex++] = (Byte)((nReadRcdNo >> 16) & 0xFF);
    byMsgReq[nIndex++] = (Byte)((nReadRcdNo >> 8) & 0xFF);
    byMsgReq[nIndex++] = (Byte)(nReadRcdNo  & 0xFF);

    //read num
    byMsgReq[nIndex++] = (Byte)((nMaxRecordNum >> 8) & 0xFF);
    byMsgReq[nIndex++] = (Byte)(nMaxRecordNum & 0xFF);

    //read direction
    byMsgReq[nIndex] = (Byte)nReadOrder;
    
    NSData* data = [[NSData alloc]initWithBytes:(void*)byMsgReq length:7];
    return data;
}

-(void) parseSensorInfoResponse:(KBeacon*) beacon dataPtr:(NSUInteger)dataPtr
response:(NSData*)sensorInfoRsp
{
    if (sensorInfoRsp.length - dataPtr < 8)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"sensor info response is null", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (self->mCmdSensorCallback != nil)
        {
            onReadSensorComplete tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(false, nil, error);
        }
        return;
    }
    

    const Byte* pSensorInfoReq = [sensorInfoRsp bytes];
    NSUInteger nIndex = dataPtr;
    ReadHTSensorInfoRsp* infoRsp = [[ReadHTSensorInfoRsp alloc]init];

    //total record number
    NSUInteger nRecordNum = htons(*(unsigned short*)&pSensorInfoReq[nIndex]);
    nIndex += 2;
    infoRsp.totalRecordNumber = [NSNumber numberWithInteger:nRecordNum];

    //unread record number
    NSUInteger nUnreadRecordNum = htons(*(unsigned short*)&pSensorInfoReq[nIndex]);
    nIndex += 2;
    infoRsp.unreadRecordNumber = [NSNumber numberWithInteger:nUnreadRecordNum];

    //utc offset
    long nUtcSeconds = htonl(*(long*)&pSensorInfoReq[nIndex]);
    infoRsp.readInfoUtcSeconds = [NSNumber numberWithLong:nUtcSeconds];
    self->utcSecondsOffset = [UTCTime getUTCTimeSecond] - nUtcSeconds;
    
    if (self->mCmdSensorCallback != nil)
    {
        onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
        self->mCmdSensorCallback = nil;
        tempCallback(true, infoRsp, nil);
    }
    return;
}


-(void) parseSensorDataResponse:(KBeacon*)beacon dataPtr:(NSUInteger)dataPtr
response:(NSData*)sensorDataRsp
{
    //sensor data type
    const Byte* pRspData = [sensorDataRsp bytes];
    NSUInteger nReadIndex = dataPtr;
    
    //read data tag
    if (pRspData[nReadIndex] != KBSensorDataTypeHumidity)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"sensor data response is null", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (self->mCmdSensorCallback != nil)
        {
            onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(false, nil, error);
        }
        return;
    }
    nReadIndex++;

    //next read data pos
    NSUInteger nNextPos = htonl(*(unsigned int*)&pRspData[nReadIndex]);
    nReadIndex += 4;

    //check payload length valid
    unsigned long nPayLoad = sensorDataRsp.length - nReadIndex;
    if (nPayLoad % 8 != 0)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"sensor data response is invalid", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (self->mCmdSensorCallback != nil)
        {
            onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(false, nil, error);
        }
        return;
    }

    //check payload length
    ReadHTSensorDataRsp* pDataRsp = [[ReadHTSensorDataRsp alloc]init];
    pDataRsp.readDataRspList = [[NSMutableArray alloc]init];
    pDataRsp.readDataNextPos = [NSNumber numberWithInteger:nNextPos];


    //read record
    NSUInteger nRecordStartPtr = nReadIndex;
    NSUInteger nTotalRecordLen = (NSUInteger)nPayLoad / 8;
    for (NSUInteger i = 0; i < nTotalRecordLen; i++)
    {
        NSUInteger nRecordPtr = nRecordStartPtr + i * 8;
        
       KBHumidityRecord* record = [[KBHumidityRecord alloc]init];

        //utc time
        NSUInteger nUtcTime = htonl(*(unsigned int*)&pRspData[nRecordPtr]);
        nRecordPtr += 4;
        if(nUtcTime < MIN_UTC_TIME_SECONDS)
        {
            nUtcTime = nUtcTime + utcSecondsOffset;
        }
        record.utcTime = [NSNumber numberWithLong:nUtcTime];

        record.temperature = [NSNumber numberWithFloat:[KBUtility signedBytes2Float:pRspData[nRecordPtr] second:pRspData[nRecordPtr+1]]];
        nRecordPtr += 2;

        record.humidity = [NSNumber numberWithFloat:[KBUtility signedBytes2Float:pRspData[nRecordPtr] second:pRspData[nRecordPtr+1]]];
        nRecordPtr += 2;

        [pDataRsp.readDataRspList addObject:record];
    }

    if (self->mCmdSensorCallback != nil)
    {
        onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
        self->mCmdSensorCallback = nil;
        tempCallback(true, pDataRsp, nil);
    }
}

@end
