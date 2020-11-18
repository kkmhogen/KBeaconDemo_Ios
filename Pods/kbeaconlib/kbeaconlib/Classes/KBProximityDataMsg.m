//
//  KBProximityDataMsg.m
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBProximityDataMsg.h"
#import "UTCTime.h"
#import "KBProximityRecord.h"

#define NB_INFO_RSP_LENGTH 6

@implementation KBProximityInfoRsp
@end
@implementation KBProximityDataRsp
@end

@implementation KBProximityDataMsg
{
    long utcSecondsOffset;
}

-(NSInteger)getSensorDataType
{
    return KBSensorDataTypeProxmity;
}

-(NSData*) makeReadSensorDataReq:(NSUInteger)nReadRcdNo order:(NSUInteger)nReadOrder
readNumber:( NSUInteger) nMaxRecordNum
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
    if (sensorInfoRsp.length - dataPtr < 6)
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
    
    //get record number
    KBProximityInfoRsp* infoRsp = [[KBProximityInfoRsp alloc]init];
    NSUInteger nRecordNum = htons(*(unsigned short*)&pSensorInfoReq[nIndex]);
    nIndex += 2;
    infoRsp.readInfoRecordNumber = [NSNumber numberWithInteger:nRecordNum];
    
    //get utc count
    long nUtcSeconds = htonl(*(long*)&pSensorInfoReq[nIndex]);
    infoRsp.readInfoUtcSeconds = [NSNumber numberWithLong:nUtcSeconds];
    
    //get utc offset
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
    if (pRspData[nReadIndex] != KBSensorDataTypeProxmity)
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

    //read next data pos
    NSUInteger nNextPos = htonl(*(unsigned int*)&pRspData[nReadIndex]);
    nReadIndex += 4;

    //check payload length valid
    unsigned long nPayLoad = sensorDataRsp.length - nReadIndex;
    if (nPayLoad % 12 != 0)
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

    KBProximityDataRsp* pDataRsp = [[KBProximityDataRsp alloc]init];
    pDataRsp.readDataList = [[NSMutableArray alloc]init];
    pDataRsp.readDataNextNum = [NSNumber numberWithInteger:nNextPos];
    
    //read record
    NSUInteger nRecordStartPtr = nReadIndex;
    NSUInteger nTotalRecordLen = (NSUInteger)nPayLoad / 12;
    for (NSUInteger i = 0; i < nTotalRecordLen; i++)
    {
        NSUInteger nRecordPtr = nRecordStartPtr + i * 12;
        KBProximityRecord* record = [[KBProximityRecord alloc]init];
        
        //nearby time
        record.nearbyTime = [NSNumber numberWithInt:pRspData[nRecordPtr++]];
        
        //mac address;
        Byte byMacAddress[3];
        byMacAddress[0] = pRspData[nRecordPtr++];
        byMacAddress[1] = pRspData[nRecordPtr++];
        byMacAddress[2] = pRspData[nRecordPtr++];
        
        NSString* strMacPrefex = [beacon.mac substringToIndex:8];
        NSData* pDMacTail = [[NSData alloc]initWithBytes:(void*)byMacAddress length:3];
        NSString* strMacTail = [KBUtility bytesToHexString:pDMacTail];
        if (strMacTail != nil)
        {
            record.mac = [NSString stringWithFormat:@"%@:%@:%@:%@",
                         strMacPrefex,
                        [strMacTail substringWithRange:(NSRange){0,2}],
                          [strMacTail substringWithRange:(NSRange){2,2}],
                          [strMacTail substringWithRange:(NSRange){4,2}]];
        }
        
        //utc time
        NSUInteger nUtcTime = htonl(*(unsigned int*)&pRspData[nRecordPtr]);
        nRecordPtr += 4;
        if(nUtcTime < MIN_UTC_TIME_SECONDS)
        {
            nUtcTime = nUtcTime + utcSecondsOffset;
        }
        record.utcTime = [NSNumber numberWithLong:nUtcTime];

        //major
        unsigned short nMajorID = htons(*(unsigned short*)&pRspData[nRecordPtr]);
        nRecordPtr += 2;
        record.majorID = [NSNumber numberWithInt:nMajorID];
        
        //minor
        unsigned short nMinorID = htons(*(unsigned short*)&pRspData[nRecordPtr]);
        nRecordPtr += 2;
        record.minorID = [NSNumber numberWithInt:nMinorID];

        [pDataRsp.readDataList addObject:record];
    }

    if (self->mCmdSensorCallback != nil)
    {
        onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
        self->mCmdSensorCallback = nil;
        tempCallback(true, pDataRsp, nil);
    }
}

@end
