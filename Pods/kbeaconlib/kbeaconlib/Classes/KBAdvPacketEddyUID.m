//
//  KBAdvEddyUID.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/17.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAdvPacketEddyUID.h"
#define EDDY_TLM_DATA_LEN 18

@implementation KBAdvPacketEddyUID

-(BOOL) parseAdvPacket:(const NSData*) data
{
    [super parseAdvPacket:data];

    int nSrvIndex = 0;
    Byte* pSrvData = (Byte*)[data bytes];
    if (pSrvData[nSrvIndex++] != 0x0)
    {
        return NO;
    }
    
    if (data.length < EDDY_TLM_DATA_LEN)
    {
        return NO;
    }
    
    //tx power
    SignedByte byRefPower = pSrvData[nSrvIndex++];
    _refTxPower = [NSNumber numberWithInt:byRefPower];
    
    Byte* pNidPtr = (Byte*)&pSrvData[nSrvIndex];
    _nid = [NSString stringWithFormat:@"0x%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            pNidPtr[0],
            pNidPtr[1],
            pNidPtr[2],
            pNidPtr[3],
            pNidPtr[4],
            pNidPtr[5],
            pNidPtr[6],
            pNidPtr[7],
            pNidPtr[8],
            pNidPtr[9]];
    nSrvIndex += 10;
    
    Byte* pBidPtr = (Byte*)&pSrvData[nSrvIndex];
    _sid = [NSString stringWithFormat:@"0x%02X%02X%02X%02X%02X%02X",
            pBidPtr[0],
            pBidPtr[1],
            pBidPtr[2],
            pBidPtr[3],
            pBidPtr[4],
            pBidPtr[5]];
    
    return YES;
}

-(KBAdvType)advType
{
    return KBAdvTypeEddyUID;
}


@end
