//
//  KBNotifyData.h
//  KBsocialAlarm
//
//  Created by hogen on 2020/8/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KBNotifyDataType)
{
    KBNotifyDataTypeInvalid = 0x0,
    KBNotifyDataTypeProxmity = 0x1,
    KBNotifyDataTypeHumidity = 0x2,
    KBNotifyDataTypeButton = 0x3,
    KBNotifyDataTypeMotion = 0x4,
} ;

@class KBeacon;
@interface KBNotifyDataBase : NSObject

//sensor data type
-(NSNumber*) getSensorDataType;

//read sensor data
-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf;

@end

NS_ASSUME_NONNULL_END
