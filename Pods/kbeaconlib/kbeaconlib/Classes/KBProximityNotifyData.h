//
//  KBProximityNotifyData.h
//  KBsocialAlarm
//
//  Created by hogen on 2020/8/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <KBNotifyDataBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBProximityNotifyData : KBNotifyDataBase

//adv information
@property (strong) NSString* mac;

@property (strong) NSNumber* nearbyTime;

@property (strong) NSNumber* majorID;

@property (strong) NSNumber* minorID;

@property (strong) NSNumber* utcTime;

@property (strong) NSNumber* nearbyDistance;


-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf;

@end

NS_ASSUME_NONNULL_END
