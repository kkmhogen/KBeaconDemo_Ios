//
//  KBCfgSleepTime.h
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBCfgSleepTime : NSObject

@property (assign, nonatomic) int mSleepStartHour;

@property (assign, nonatomic) int mSleepStartMinute;

@property (assign, nonatomic) int mSleepEndHour;

@property (assign, nonatomic) int mSleepEndMinute;

-(BOOL) isSleepTimeEnable;

@end

NS_ASSUME_NONNULL_END
