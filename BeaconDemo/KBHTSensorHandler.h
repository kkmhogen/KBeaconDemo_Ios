//
//  KBHTSensorOpteration.h
//  kbeaconlib_Example
//
//  Created by hogen on 2020/11/17.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KBeacon.h>
#import <KBSubscribeNotifyItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBHTSensorHandler : NSObject<KBNotifyDataDelegate>

@property (weak, nonatomic) KBeacon* mBeacon;

-(void)enableTHRealtimeDataToAdv;

-(void)enableTHRealtimeDataToApp;

-(void)enableTHTriggerEvtRpt2Adv;

-(void) enableTHTriggerEvtRpt2App;

@end

NS_ASSUME_NONNULL_END
