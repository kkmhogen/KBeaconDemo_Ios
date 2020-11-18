//
//  KBAdvPacketHandler.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/22.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAdvPacketHandler.h"
#import "KBAdvPacketIBeacon.h"
#import "KBAdvPacketEddyURL.h"
#import "KBAdvPacketEddyUID.h"
#import "KBAdvPacketEddyTLM.h"
#import "KBAdvPacketIBeacon.h"
#import "KBAdvPacketSensor.h"


//key beacon type key
/*
#define KBiBeaconKey @"iBeacon"
#define KBEddyURLKey @"eddyURL"
#define KBEddyTLMKey @"eddyTLM"
#define KBEddyUIDKey @"eddyUID"
#define KBSensorKey @"kbSensor"
*/

#define MIN_IBEACON_ADV_LEN 6
#define MIN_EDDY_TLM_ADV_LEN (14)
#define MIN_EDDY_UID_ADV_LEN (1+1+16)
#define MIN_EDDY_URL_ADV_LEN (1+1+1)
#define MIN_SENSOR_ADV_LEN (1+1+1)

static NSDictionary* kbAdvPacketTypeObjects;


@implementation KBAdvPacketHandler
{
    NSMutableDictionary* mAdvPackets;
}


+(void)initialize
{
    kbAdvPacketTypeObjects = @{
                               [NSString stringWithFormat:@"%ld",(long)KBAdvTypeIBeacon]:
                             KBAdvPacketIBeacon.class,
                               [NSString stringWithFormat:@"%ld",(long)KBAdvTypeEddyUID]:
                             KBAdvPacketEddyUID.class,
                               [NSString stringWithFormat:@"%ld",(long)KBAdvTypeEddyURL]:
                             KBAdvPacketEddyURL.class,
                               [NSString stringWithFormat:@"%ld",(long)KBAdvTypeEddyTLM]:
                             KBAdvPacketEddyTLM.class,
                               [NSString stringWithFormat:@"%ld",(long)KBAdvTypeSensor]:
                             KBAdvPacketSensor.class,
                         };
}

-(id) init
{
    self = [super init];
    mAdvPackets = [[NSMutableDictionary alloc]initWithCapacity:4];
    
    return self;
}

-(NSArray*) advPackets
{
    if (mAdvPackets == nil || mAdvPackets.count == 0)
    {
        return nil;
    }
    
    return [mAdvPackets allValues];
}

-(KBAdvPacketBase*)getAdvPacket:(KBAdvType) advType
{
    NSString* strAdvTypeKey = [NSString stringWithFormat:@"%ld", (long)advType];
    
    return [mAdvPackets objectForKey:strAdvTypeKey];
}

-(BOOL) parseAdvPacket:(NSDictionary*) advData rssi:(NSNumber*)rssi
{
    BOOL bParseDataRslt = FALSE;
    NSString* deviceName;
    NSNumber *advConnable;
    NSData* pAdvData = nil;
    
    //device name
    deviceName = [advData objectForKey:@"kCBAdvDataLocalName"];
    
    //is connectable
    advConnable = [advData objectForKey:@"kCBAdvDataIsConnectable"];
    
    NSDictionary* kbServiceData = [advData objectForKey:@"kCBAdvDataServiceData"];
    if (kbServiceData == nil){
        return FALSE;
    }
   
    KBAdvType advType = KBAdvTypeInvalid;
    
    //check if include eddystone data
    NSData* pEddyAdvData = [kbServiceData objectForKey:PARCE_UUID_EDDYSTONE];
    if (pEddyAdvData != nil && pEddyAdvData.length > 1)
    {
        //eddy stone frame
        Byte* pTempSrvData = (Byte*)[pEddyAdvData bytes];
        
        //eddytone url adv
        if (pTempSrvData[0] == 0x0
            && pEddyAdvData.length >= MIN_EDDY_UID_ADV_LEN)
        {
            advType = KBAdvTypeEddyUID;
            pAdvData = pEddyAdvData;
        }
        //eddystone uid adv
        else if (pTempSrvData[0] == 0x10
                 && pEddyAdvData.length >= MIN_EDDY_URL_ADV_LEN)
        {
            advType = KBAdvTypeEddyURL;
            pAdvData = pEddyAdvData;
        }
        //eddystone tlm adv
        else if (pTempSrvData[0] == 0x20
                 && pEddyAdvData.length >= MIN_EDDY_TLM_ADV_LEN)
        {
            advType = KBAdvTypeEddyTLM;
            pAdvData = pEddyAdvData;
        }
        else if (pTempSrvData[0] == 0x21
                 && pEddyAdvData.length >= MIN_SENSOR_ADV_LEN)
        {
            advType = KBAdvTypeSensor;
            pAdvData = pEddyAdvData;
        }
        else
        {
            advType = KBAdvTypeInvalid;
        }
    }
    
    NSData* pExtService = [kbServiceData objectForKey:PARCE_UUID_KB_EXT_DATA];
    if (pExtService != nil && pExtService.length > 2)
    {
        Byte* pTempSrvData = (Byte*)[pExtService bytes];
        int nBattPercent = pTempSrvData[0];
        if (nBattPercent > 100)
        {
            nBattPercent = 100;
        }
        _batteryPercent = [NSNumber numberWithInt:nBattPercent];
        
        
        //beacon extend data
        if (((pTempSrvData[1] & KBAdvTypeIBeacon) > 0)
            && advType == KBAdvTypeInvalid)
        {
            //find ibeacon instance
            advType = KBAdvTypeIBeacon;
            pAdvData = pExtService;
        }
    }
    
    //check filter
    if (_filterAdvType != nil
        && ([_filterAdvType intValue] & advType) == 0)
    {
        return NO;
    }
    
    //parse data
    if (advType != KBAdvTypeInvalid)
    {
        NSString* strAdvTypeKey = [NSString stringWithFormat:@"%ld", (long)advType];
        KBAdvPacketBase* advPacket = [mAdvPackets objectForKey:strAdvTypeKey];
        Boolean bNewObj = false;
        if (advPacket == nil)
        {
            Class class = [kbAdvPacketTypeObjects objectForKey:strAdvTypeKey];
            advPacket = [[class alloc]init];
            bNewObj = true;
        }
        
        //check if parse advertisment packet success
        if (pAdvData.length > 0
            && [advPacket parseAdvPacket:pAdvData])
        {
            [advPacket updateBasicInfo:deviceName
                                   rssi:rssi
                            connectable:advConnable];
            bParseDataRslt = TRUE;
            if (bNewObj)
            {
                [mAdvPackets setObject:advPacket forKey:strAdvTypeKey];
            }
        }
    }
    
    return bParseDataRslt;
}

@end
