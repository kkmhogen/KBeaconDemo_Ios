//
//  AdvPacket.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/17.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAdvPacketBase.h"



@implementation KBAdvPacketBase

-(BOOL) parseAdvPacket:(const NSData*) data
{
    _lastReceiveTime = [[NSDate date]timeIntervalSince1970];
    
    return YES;
}

-(KBAdvType) advType
{
    return KBAdvTypeInvalid;
}

-(void) updateBasicInfo:(NSString*)name
                   rssi:(NSNumber*)rssi
            connectable:(NSNumber*)connectable
{
    _name = name;
    _rssi = rssi;
    _connectable = connectable;
}

@end
