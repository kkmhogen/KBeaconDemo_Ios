//
//  KBNotifyData.h
//  KBsocialAlarm
//
//  Created by hogen on 2020/8/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KBeacon;
@interface KBNotifyData : NSObject

//sensor data type
-(int) getSensorDataType;

//read sensor data
-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf;

@end

NS_ASSUME_NONNULL_END
