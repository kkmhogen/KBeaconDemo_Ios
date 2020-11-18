//
//  KBHumidityNotifyData.h
//  KBeacon
//
//  Created by hogen on 2020/11/15.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KBNotifyDataBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBHumidityNotifyData : KBNotifyDataBase

@property (strong, readonly) NSNumber* temperature;

@property (strong, readonly) NSNumber* humidity;

@property (strong, readonly) NSNumber* eventUTCTime;


//sensor data type
-(NSNumber*) getSensorDataType;

//read sensor data
-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf;

@end

NS_ASSUME_NONNULL_END
