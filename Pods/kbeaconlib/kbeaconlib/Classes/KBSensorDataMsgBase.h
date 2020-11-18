//
//  KBSensorDataMsgBase.h
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KBeacon.h>

NS_ASSUME_NONNULL_BEGIN

#define READ_RECORD_REVERSE_ORDER 1
#define READ_RECORD_ORDER  0
#define READ_RECORD_NEW_RECORD  2

#define MSG_READ_SENSOR_CTRL_TAG  1
#define MSG_READ_SENSOR_DATA_TAG  2
#define MSG_CLEAR_SENSOR_DATA_TAG 3

#define INVALID_DATA_RECORD_POS  0xFFFFFFFF
#define MIN_UTC_TIME_SECONDS 946080000


typedef NS_ENUM(NSInteger, KBSensorDataType)
{
    KBSensorDataTypeInvalid = 0x0,
    KBSensorDataTypeProxmity = 0x1,
    KBSensorDataTypeHumidity = 2
} ;

//read sensor data callback
typedef void (^onSensorDataCommandCallback)(BOOL bConfigSuccess, NSObject* _Nullable obj, NSError* _Nullable  error);

@interface KBSensorDataMsgBase : NSObject
{
    onSensorDataCommandCallback mCmdSensorCallback;
}

-(NSInteger) getSensorDataType;

-(NSData*) makeReadSensorDataReq:(NSUInteger)nReadRcdNo order:(NSUInteger)nReadOrder
                      readNumber:( NSUInteger) nMaxRecordNum;

//parse data message
-(void) parseSensorDataResponse:(KBeacon*)beacon dataPtr:(NSUInteger)dataPtr
  response:(NSData*)sensorDataRsp;

//parase sensor message
-(void) parseSensorInfoResponse:(KBeacon*) beacon dataPtr:(NSUInteger)dataPtr response:(NSData*)sensorDataRsp;

//read sensor info
-(void) readSensorDataInfo:(KBeacon*) beacon
                  callback:(onSensorDataCommandCallback) readCallback;

//read sensor data
-(void)readSensorRecord:(KBeacon*)beacon
              recordNum:(NSUInteger)nReadRcdNo
                  order:(NSUInteger) nReadOrder
           maxRecordNum:(NSUInteger)nMaxRecordNum
               callback:(onSensorDataCommandCallback) readCallback;

//clear sensor record
-(void)clearSensorRecord:(KBeacon*)beacon
                callback:(onSensorDataCommandCallback) readCallback;

@end

NS_ASSUME_NONNULL_END
