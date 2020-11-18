//
//  UTCTime.h
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UTCTime : NSObject

@property (assign, nonatomic) int mYear;

@property (assign, nonatomic) int mMonth;

@property (assign, nonatomic) int mDays;

@property (assign, nonatomic) int mHours;

@property (assign, nonatomic) int mMinutes;

@property (assign, nonatomic) int mSeconds;

+(NSTimeInterval) getUTCTimeSecond;

+(UTCTime*) getLocalTimeFromUTC: (int)hour minute:(int) minute second:(int) second;

+(UTCTime*) getUTCFromLocalTime:(int)hour minute:(int)minute second:(int)seconds;

@end

NS_ASSUME_NONNULL_END
