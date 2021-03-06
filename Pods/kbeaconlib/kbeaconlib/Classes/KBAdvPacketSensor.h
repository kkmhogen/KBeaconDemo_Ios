//
//  KBAdvPacketSensor.h
//  KBeaconConfig
//
//  Created by kkm on 2019/7/22.
//  Copyright © 2019 kkm. All rights reserved.
//

#import <KBAdvPacketBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBAccSensorValue : NSObject
@property (strong) NSNumber* xAis;
@property (strong) NSNumber* yAis;
@property (strong) NSNumber* zAis;
@end

@interface KBAdvPacketSensor : KBAdvPacketBase

//acceleration sensor data
@property (strong, readonly) KBAccSensorValue* accSensor;

//temperature about sensor
@property (strong, readonly) NSNumber* temperature;

//humidity about sensor
@property (strong, readonly) NSNumber* humidity;

//adv packet version
@property (strong, readonly) NSNumber* version;

//battery level, uint is mV
@property (strong, readonly) NSNumber* batteryLevel;

-(BOOL) parseAdvPacket:(const NSData*) data;

@end

NS_ASSUME_NONNULL_END
