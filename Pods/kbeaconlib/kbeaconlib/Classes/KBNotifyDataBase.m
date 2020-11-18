//
//  KBNotifyData.m
//  KBsocialAlarm
//
//  Created by hogen on 2020/8/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBNotifyDataBase.h"

@implementation KBNotifyDataBase

-(NSNumber*) getSensorDataType
{
    return [NSNumber numberWithInt: KBNotifyDataTypeInvalid];
}

-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf
{
    
}

@end
