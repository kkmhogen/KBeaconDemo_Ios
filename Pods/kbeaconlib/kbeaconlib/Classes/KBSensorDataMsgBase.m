//
//  KBSensorDataMsgBase.m
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBSensorDataMsgBase.h"

@implementation KBSensorDataMsgBase

-(NSInteger) getSensorDataType
{
    return KBSensorDataTypeInvalid;
}

-(NSData*) makeReadSensorDataReq:(NSUInteger)nReadRcdNo order:(NSUInteger)nReadOrder
                      readNumber:( NSUInteger) nMaxRecordNum
{
    return nil;
}

-(void) parseSensorDataResponse:(KBeacon*)beacon dataPtr:(NSUInteger)dataPtr
  response:(NSData*)sensorDataRsp
{
    return;
}

-(void) parseSensorInfoResponse:(KBeacon*) beacon dataPtr:(NSUInteger)dataPtr
                       response:(NSData*)sensorInfoRsp
{
    return;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
-(void) readSensorDataInfo:(KBeacon*) beacon callback:(onSensorDataCommandCallback) readCallback
{
    Byte bySensorInfoReq[2];

    bySensorInfoReq[0] = MSG_READ_SENSOR_CTRL_TAG;
    bySensorInfoReq[1] = (Byte)[self getSensorDataType];
    NSData* reqData = [[NSData alloc]initWithBytes:bySensorInfoReq length:2];
    
    self->mCmdSensorCallback = readCallback;

       //send message
    [beacon sendSensorRequest:reqData callback:^(BOOL bConfigSuccess, NSData * _Nullable data, NSError * _Nullable error) {
        if (bConfigSuccess)
        {
            [self parseSensorInfoResponse:beacon dataPtr:2 response:data];
        }
        else
        {
            if (self->mCmdSensorCallback != nil)
            {
                onReadSensorComplete tempCallback = self->mCmdSensorCallback;
                self->mCmdSensorCallback = nil;
                tempCallback(false, nil, error);
            }
        }
    }];
}

-(NSUInteger)parseSensorDataResponse:(NSData*)data
{
    Byte byData[3];
    if (data == nil || data.length < 3)
    {
        return INVALID_DATA_RECORD_POS;
    }
    
    [data getBytes:byData length:3];
    if (byData[0] != MSG_READ_SENSOR_DATA_TAG)
    {
        return INVALID_DATA_RECORD_POS;
    }
    
    //data length
    unsigned short nDataLen = htons(*(unsigned short*)&byData[1]);
    if (nDataLen != data.length - 3)
    {
        return INVALID_DATA_RECORD_POS;
    }
    
    return nDataLen;
}

-(void)readSensorRecord:(KBeacon*)beacon
              recordNum:(NSUInteger)nReadRcdNo
                  order:(NSUInteger) nReadOrder
           maxRecordNum:(NSUInteger)nMaxRecordNum
               callback:(onSensorDataCommandCallback) readCallback
{

    NSData* byMsgBody = [self makeReadSensorDataReq:nReadRcdNo order:nReadOrder readNumber:nMaxRecordNum];
    if (byMsgBody == nil)
    {
       NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"request is null", NSLocalizedDescriptionKey, @"request is null", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
       NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgInputInvalid userInfo:userInfo1];
       
        if (readCallback != nil)
        {
            readCallback(false, nil, error);
        }
       return;
    }


    self->mCmdSensorCallback = readCallback;
    unsigned long nMsgTotalLen = byMsgBody.length + 2;
    NSMutableData* dataMsgReq = [[NSMutableData alloc]initWithCapacity:nMsgTotalLen];
    
    //add head
    Byte byMsgHead[2] = {MSG_READ_SENSOR_DATA_TAG, 0};
    byMsgHead[1] = [self getSensorDataType];
    [dataMsgReq appendBytes:(void*)byMsgHead length:2];
    
    //add mssage body
    [dataMsgReq appendData:byMsgBody];
    
    //send message to device
    [beacon sendSensorRequest:dataMsgReq callback:^(BOOL bConfigSuccess, NSData * _Nullable data, NSError * _Nullable error)
    {
        if (bConfigSuccess)
        {
            //tag
            if ([self parseSensorDataResponse:data] == INVALID_DATA_RECORD_POS)
            {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"read data fail", NSLocalizedDescriptionKey, @"read data is null", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
                
                if (readCallback != nil)
                {
                    readCallback(false, nil, error);
                }
            }
            
            [self parseSensorDataResponse:beacon dataPtr:3 response:data];
        } else {
            
            if (self->mCmdSensorCallback != nil)
            {
                onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
                self->mCmdSensorCallback = nil;
                tempCallback(false, nil, error);
            }
        }
    }];
}

-(void)clearSensorRecord:(KBeacon*)beacon
    callback:(onSensorDataCommandCallback) readCallback
{
    Byte bySensorInfoReq[2] ;
    bySensorInfoReq[0] = MSG_CLEAR_SENSOR_DATA_TAG;
    bySensorInfoReq[1] = [self getSensorDataType];
    self->mCmdSensorCallback = readCallback;

    NSData* pMsgReq = [[NSData alloc]initWithBytes:(void*)bySensorInfoReq length:2];
    [beacon sendSensorRequest:pMsgReq callback:^(BOOL bConfigSuccess, NSData * _Nullable data, NSError * _Nullable error)
    {
        if (self->mCmdSensorCallback != nil)
        {
            onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(bConfigSuccess, nil, error);
        }
    }];
}
     
@end
