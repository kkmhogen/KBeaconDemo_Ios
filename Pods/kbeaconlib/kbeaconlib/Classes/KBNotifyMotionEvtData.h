//
//  KBNotifyMotionEvtData.h
//  kbeaconlib
//
//  Created by hogen on 2021/1/30.
//

#import <Foundation/Foundation.h>
#import "KBNotifyDataBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface KBNotifyMotionEvtData : KBNotifyDataBase

@property (strong) NSNumber* motionNtfEvent;

-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf;

@end

NS_ASSUME_NONNULL_END
