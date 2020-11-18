//
//  KBeaconsMgr.h
//  KBeaconsMgr
//
//  Created by kkm on 2018/12/10.
//  Copyright © 2018 kkm. All rights reserved.
//

#import "KBeaconsMgr.h"
#import "KBUtility.h"
#import "KBUtility.h"
#import "KBeacon.h"
#import "KBAdvPacketBase.h"
#import "KBAdvPacketIBeacon.h"

#define MAX_TIMER_OUT_INTERVAL 0.3

@implementation KBeaconsMgr
{
    CBCentralManager *mCbBeaconDevMgr;  //esl device manager
    
    NSTimer *mPeriodTimer;
    
    BOOL mScanFilterNameCaseIgnore;
    
    //all beacons, include kkm beacons and other unknown beacons
    NSMutableDictionary* mCbAllBeacons;
    
    //kkm beacons
    NSMutableDictionary* mCbKBeacons;
    
    //the beacon that need notify to ui
    NSMutableDictionary* mCBNtfBeacons;
}

+ (KBeaconsMgr *)sharedBeaconManager
{
    static KBeaconsMgr * sharedStaticBeaconManager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedStaticBeaconManager = [[self alloc] init];
    });
    return sharedStaticBeaconManager;
}

- (id) init
{
    self = [super init];
    
    
    mCbBeaconDevMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    mCbKBeacons = [NSMutableDictionary dictionaryWithCapacity: 50];
    mCbAllBeacons = [NSMutableDictionary dictionaryWithCapacity: 100];
    
    mCBNtfBeacons = [NSMutableDictionary dictionaryWithCapacity:10];
    
    return self;
}

-(NSDictionary*)Beacons
{
    return mCbKBeacons;
}

-(void)clearBeacons
{
    NSEnumerator * enumeratorValue = [mCbKBeacons objectEnumerator];
    for (KBeacon *beacon in enumeratorValue) {
        [beacon disconnect];
    }
    
    //clear all scaned ble device
    [mCbAllBeacons removeAllObjects];
    
    //clear KBeacon list
    [mCbKBeacons removeAllObjects];
    
    //clear notify list
    [mCBNtfBeacons removeAllObjects];
}

//scanning ESL
-(int) startScanning
{
    //check if ble function enable
    if (self.centralBLEState == BLEStateUnauthorized)
    {
        return SCAN_ERROR_NO_PERMISSION;
    }
    else if (self.centralBLEState == BLEStatePowerOff)
    {
        return SCAN_ERROR_BLE_NOT_ENABLE;
    }
    else if (self.centralBLEState == BLEStateUnknown)
    {
        return SCAN_ERROR_UNKNOWN;
    }
    
    //stop privous scan
    [mCbBeaconDevMgr stopScan];
    
    //scan option
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],CBCentralManagerScanOptionAllowDuplicatesKey,nil];
    
    //NSArray* filterSrvList = @[SRV_CFG_UUID_EDDYSTONE];
    [mCbBeaconDevMgr scanForPeripheralsWithServices:nil options:options]; // Start scanning
    NSLog(@"start central ble device scanning");
    
    return 0;
}

-(BOOL) isScanning
{
    return [mCbBeaconDevMgr isScanning];
}

-(void)stopScanning
{
    NSLog(@"stop central ble device scanning");
    
    [mCbBeaconDevMgr stopScan];
}

//scan name filter
-(void)setScanNameFilter:(NSString*) strFilterName caseIgnore:(BOOL)caseIgnore
{
    _scanNameFilter = strFilterName;
    mScanFilterNameCaseIgnore = caseIgnore;
}

//scan name filter
-(void)setScanAdvTypeFilter:(NSNumber*)advFilterType
{
    _scanAdvTypeFilter = advFilterType;
}

//rssi filter
-(void)setScanRssiFilter:(NSNumber*) minRssi
{
    if ([minRssi intValue] >= -100 && [minRssi intValue] < -20)
    {
        _scanMinRssiFilter = minRssi;
    }
    else
    {
        NSLog(@"rssi filter value range invalid");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([RSSI intValue] == 127)
    {
        RSSI = [NSNumber numberWithInt:-100];
    }
                
    //filter
    if (_scanMinRssiFilter != nil)
    {
        if ([RSSI intValue] < [_scanMinRssiFilter intValue])
        {
            return;
        }
    }
    
    //name filter
    if (_scanNameFilter != nil && _scanNameFilter.length >= 1)
    {
        NSString* strAdvName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
        if (strAdvName != nil)
        {
            if (mScanFilterNameCaseIgnore)
            {
                NSString* strLowCaseAdvName = [strAdvName lowercaseString];
                NSString* strFilterNoCase = [_scanNameFilter lowercaseString];
                if (![strLowCaseAdvName containsString:strFilterNoCase])
                {
                    return;
                }
            }
            else if (![strAdvName containsString:_scanNameFilter])
            {
                return;
            }
        }
        else
        {
            return;
        }
    }
    
    KBeacon* pUnknownBeacon = nil;
    BOOL bParseAdvData = FALSE;
    if (advertisementData != nil && advertisementData.count > 0)
    {
        pUnknownBeacon = [mCbAllBeacons objectForKey:peripheral.identifier.UUIDString];
        if (pUnknownBeacon == nil)
        {
            pUnknownBeacon = [[KBeacon alloc]initWithUUID:peripheral.identifier.UUIDString];
            [pUnknownBeacon setAdvTypeFilter:_scanAdvTypeFilter];
            
            [mCbAllBeacons setObject:pUnknownBeacon forKey:peripheral.identifier.UUIDString];
        }
        bParseAdvData = [pUnknownBeacon parseAdvPacket:advertisementData rssi:RSSI];
    }
    
    //parse success, add to
    if (bParseAdvData)
    {
        KBeacon* pKBeacon = [mCbKBeacons objectForKey:peripheral.identifier.UUIDString];
        if (pKBeacon == nil)
        {
            [pUnknownBeacon attach2Device:peripheral beaconMgr:self];
            [mCbKBeacons setObject:pUnknownBeacon forKey:peripheral.identifier.UUIDString];
        }
        
        //add to beacons list
        [mCBNtfBeacons setObject:pUnknownBeacon forKey:peripheral.identifier.UUIDString];
        
        if (mPeriodTimer == nil || !mPeriodTimer.isValid)
        {
            mPeriodTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_TIMER_OUT_INTERVAL target:self selector:@selector(delayReportAdvTimer:) userInfo:nil repeats:NO];
        }
    }
}

-(CBCentralManager*) getBLECentralMgr
{
    return mCbBeaconDevMgr;
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
{
    NSLog(@"central manager connect to gatt:%@ success", peripheral.identifier.UUIDString);
    
    KBeacon* pBeacon = (KBeacon*)[self.Beacons objectForKey:peripheral.identifier.UUIDString];
    if (pBeacon != nil)
    {
        [pBeacon handleCentralBLEEvent:peripheral.state];
    }
    else
    {
        [mCbBeaconDevMgr cancelPeripheralConnection:peripheral];
    }
    
    return;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"central manager disconnection to device:%@", peripheral.identifier.UUIDString);
    KBeacon* pBeacon = (KBeacon*)[self.Beacons objectForKey:peripheral.identifier.UUIDString];
    if (pBeacon != nil)
    {
        [pBeacon handleCentralBLEEvent:CBPeripheralStateDisconnected];
    }
}



- (void) delayReportAdvTimer:(NSTimer *)timer
{
    
    if (mCBNtfBeacons.count > 0)
    {
        NSMutableArray* pBeaconArray = [NSMutableArray arrayWithCapacity:10];
        NSEnumerator * enumeratorValue = [mCBNtfBeacons objectEnumerator];
        for (NSObject *object in enumeratorValue) {
            [pBeaconArray addObject:object];
        }
        
        //call back
        [self.delegate onBeaconDiscovered:pBeaconArray];
        
        [mCBNtfBeacons removeAllObjects];
    }
}

-(void)waitCentralBLEPowerOnCallback:(NSTimer *)timer
{
    NSLog(@"Wait Central BLE manager power on timeout%d\r\n", (int)self.centralBLEState);
}

-(BLECentralMgrState) centralBLEState
{
    if (mCbBeaconDevMgr.state == CBManagerStatePoweredOn)
    {
        return BLEStatePowerOn;
    }
    else if (mCbBeaconDevMgr.state == CBManagerStatePoweredOff
             || mCbBeaconDevMgr.state == CBManagerStateResetting)
    {
        return BLEStatePowerOff;
    }
    else if (mCbBeaconDevMgr.state == CBManagerStateUnauthorized)
    {
        return BLEStateUnauthorized;
    }
    else
    {
        return BLEStateUnknown;
    }
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Status of CoreBluetooth central manager changed %d\r\n",
          (int)central.state);
    
    switch (central.state)
    {
        case CBManagerStatePoweredOn:
        {
            [self.delegate onCentralBleStateChange:BLEStatePowerOn];
            break;
        }
            
        case CBManagerStatePoweredOff:
        case CBManagerStateResetting:
        {
            [self.delegate onCentralBleStateChange:BLEStatePowerOff];
            break;
        }
            
        case CBManagerStateUnauthorized:
        {
            [self.delegate onCentralBleStateChange:BLEStateUnauthorized];
            break;
        }
       
        default:
            [self.delegate onCentralBleStateChange:BLEStateUnknown];
            NSLog(@"error for blue status");
            break;
    }
}

@end
