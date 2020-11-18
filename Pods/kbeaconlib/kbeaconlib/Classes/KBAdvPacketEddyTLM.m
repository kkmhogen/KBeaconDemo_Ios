//
//  KBAdvEddyTLM.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/17.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAdvPacketEddyTLM.h"
#define DAYS_SECONDS (3600*24)
@implementation TLMElapseTime
@end

@implementation KBAdvPacketEddyTLM

-(BOOL) parseAdvPacket:(const NSData*) data
{
    [super parseAdvPacket:data];
    
    int nSrvIndex = 0;
    Byte* pSrvData = (Byte*)[data bytes];
    
    //frame type
    if (pSrvData[nSrvIndex++] != 0x20)
    {
        return NO;
    }
    
    //version
    _tlmType = [NSNumber numberWithInt:pSrvData[nSrvIndex++]];
    
    //battery
    int nBatteryLevel;
    nBatteryLevel = (pSrvData[nSrvIndex++] & 0xFF);
    nBatteryLevel = (nBatteryLevel << 8);
    nBatteryLevel += (pSrvData[nSrvIndex++] & 0xFF);
    _batteryLevel = [NSNumber numberWithInt:nBatteryLevel];
    
    //temputure
    Byte tempHeigh = pSrvData[nSrvIndex++];
    Byte tempLow = pSrvData[nSrvIndex++];
    float fTempRsult =[KBUtility signedBytes2Float:tempHeigh second:tempLow];
    _temperature = [NSNumber numberWithFloat:fTempRsult];
    
    //adv count
    int nAdvCount = (pSrvData[nSrvIndex++] & 0xFF);
    for (int i = 0; i < 3; i++)
    {
        nAdvCount = (nAdvCount << 8);
        nAdvCount += (pSrvData[nSrvIndex] & 0xFF);
        nSrvIndex++;
    }
    _advCount = [NSNumber numberWithInt:nAdvCount];
    
    //sec count
    int secCount = (pSrvData[nSrvIndex++] & 0xFF);
    for (int i = 0; i < 3; i++)
    {
        secCount = (secCount << 8);
        secCount += (pSrvData[nSrvIndex] & 0xFF);
        nSrvIndex++;
    }
    float fSecOunt = secCount;
    fSecOunt = fSecOunt / 10;
    _secCount = [NSNumber numberWithFloat:fSecOunt];
    
    return YES;
}

-(TLMElapseTime*) getElapseTime
{
    TLMElapseTime* elapseTime = [[TLMElapseTime alloc]init];

    elapseTime.days = (int)([self.secCount longValue] / DAYS_SECONDS);
    long nRemainsSec = (int)([self.secCount longValue] % DAYS_SECONDS);
    elapseTime.hours = (int)(nRemainsSec / 3600);
    nRemainsSec = nRemainsSec % 3600;
    elapseTime.minutes = (int)(nRemainsSec / 60);
    elapseTime.second = (int)(nRemainsSec % 60);

    return elapseTime;
}

-(KBAdvType)advType
{
    return KBAdvTypeEddyTLM;
}

@end
