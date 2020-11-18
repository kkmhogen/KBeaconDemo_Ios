//
//  KBNotifyData.m
//  KBsocialAlarm
//
//  Created by hogen on 2020/8/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBNotifyData.h"
#import "KBNotifyDataBase.h"

@implementation KBNotifyData

-(int) getSensorDataType
{
    return KBNotifyDataTypeInvalid;
}

-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf
{
    
}

@end
