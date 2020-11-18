//
//  KBAdvPacketIBeacon.m
//  KBAdvPacketIBeacon
//
//  Created by kkm on 2019/7/17.
//  Copyright © 2019 kkm. All rights reserved.
//
#import "KBAdvPacketIBeacon.h"


#define MIN_IBEACON_SRV_DATA 6

@implementation KBAdvPacketIBeacon

-(BOOL) parseAdvPacket:(const NSData*) data
{
    [super parseAdvPacket:data];
    
    const Byte* pBytes = (Byte*)[data bytes];
    if ((pBytes[1] & KBAdvTypeIBeacon) == 0)
    {
        return NO;
    }
    
    //major id
    int nMajorID = pBytes[2];
    nMajorID = (nMajorID << 8) + pBytes[3];
    _majorID = [NSNumber numberWithInteger: nMajorID];
    
    //minor id
    int nMinorID = pBytes[4];
    nMinorID = (nMinorID << 8) + pBytes[5];
    _minorID = [NSNumber numberWithInteger:nMinorID];

    return YES;
}

-(KBAdvType) advType
{
    return KBAdvTypeIBeacon;
}


@end
