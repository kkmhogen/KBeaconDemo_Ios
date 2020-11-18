//
//  KBCfgSleepTime.m
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBCfgSleepTime.h"

@implementation KBCfgSleepTime

- (id)init
{
    self = [super init];
    self.mSleepStartHour = self.mSleepStartMinute =
    self.mSleepEndHour = self.mSleepEndMinute = 0;

    return self;
}

-(BOOL)isSleepTimeEnable
{
    if (self.mSleepStartHour == self.mSleepEndHour
        && self.mSleepStartMinute == self.mSleepEndMinute)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


@end
