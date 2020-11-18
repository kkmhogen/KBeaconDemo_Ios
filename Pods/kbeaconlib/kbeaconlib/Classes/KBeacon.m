//
//  BeaconDevice.m
//  ESLConfig
//
//  Created by kkm on 2018/12/8.
//  Copyright © 2018 kkm. All rights reserved.
//

#import "KBeacon.h"
#import "KBUtility.h"
#import "KBeaconsMgr.h"
#import "KBAdvPacketHandler.h"
#import "KBAuthHandler.h"
#import "KBCfgHandler.h"
#import "KBException.h"
#import "KBCfgTrigger.h"
#import "KBCfgNearbyTrigger.h"
#import "KBSubscribeNotifyItem.h"
#import "KBCfgHumidityTrigger.h"


#define MAX_CONNING_TIME_SEC 15
#define MAX_READ_CFG_TIMEOUT 15

#define ACTION_INIT_READ_CFG 3
#define ACTION_WRITE_CFG 1
#define ACTION_WRITE_CMD 2
#define ACTION_IDLE 0
#define ACTION_USR_READ_CFG 4
#define ACTION_READ_SENSOR 5
#define ACTION_ENABLE_NTF  6

//data type
#define DATA_TYPE_AUTH 0x1
#define DATA_TYPE_JSON 0x2


//frame tag
#define PDU_TAG_START 0x0
#define PDU_TAG_MIDDLE 0x1
#define PDU_TAG_END 0x2
#define PDU_TAG_SINGLE 0x3

//down hex file
//upload json data
#define CENT_PERP_TX_HEX_DATA  0
#define PERP_CENT_TX_HEX_ACK  0

//down json data
#define CENT_PERP_TX_JSON_DATA  2
#define PERP_CENT_TX_JSON_ACK  2

//upload json data
#define PERP_CENT_DATA_RPT  3
#define CENT_PERP_DATA_RPT_ACK  3

//upload hex data
#define PERP_CENT_HEX_DATA_RPT  5
#define CENT_PERP_HEX_DATA_RPT_ACK  5

#define BEACON_ACK_SUCCESS 0x0
#define BEACON_ACK_EXPECT_NEXT 0x4
#define BEACON_ACK_CAUSE_CMD_RCV 0x5
#define BEACON_ACK_CMD_CMP 0x6

//max mtu size
#define MIN_BLE_MTU_SIZE 20
#define MAX_BLE_MTU_SIZE 251

#define MSG_PDU_HEAD_LEN 0x3
#define DATA_ACK_HEAD_LEN 0x6

//buffer size
#define MAX_BUFFER_DATA_SIZE 1024

@implementation KBeacon
{    
    KBeaconsMgr *mBeaconsMgr;
    
    //adv packet manager
    KBAdvPacketHandler* mAdvPacketMgr;
    
    //para config manager
    KBCfgHandler* mCfgMgr;
    
    //authentication handler;
    KBAuthHandler* mAuthHandler;
    
    NSTimer* mConnectingTimer;
    NSTimer* mDisconntingTimer;

    NSTimer* mActionTimer;

    
    NSString* mPassword;
    
    NSData* mByDownloadDatas;
    Byte mByDownDataType;
    
    Byte mLockState;
    
    Byte mActionStatus;
    NSArray* mActionArray;
    
    Byte mAuthPhase1AppRandom[4];
    Byte mAuthDeviceMac[6];
    
    onReadComplete mReadCfgCallback;
    
    onActionComplete mWriteCfgCallback;
    
    onActionComplete mWriteCmdCallback;
    
    onReadSensorComplete mReadSensorCallback;
    
    onActionComplete mEnableSubscribeNotifyCallback;

    NSMutableData* mReceiveData;
    
    NSArray<KBCfgBase*>* mToBeCfgData;
        
    NSMutableDictionary* notifyData2ClassMap;

    KBSubscribeNotifyItem* mToAddedSubscribeInstance;

    int mCloseReason;
}

-(id) init
{
    self = [super init];
    
    mAdvPacketMgr = [[KBAdvPacketHandler alloc]init];
    
    mCfgMgr = [[KBCfgHandler alloc]init];
    
    mAuthHandler = [[KBAuthHandler alloc] init];
    mAuthHandler.delegate = self;
    
    notifyData2ClassMap = [[NSMutableDictionary alloc]init];
    
    return self;
}

-(id) initWithUUID:(NSString*)uuidString
{
    self = [self init];
    
    mAdvPacketMgr = [[KBAdvPacketHandler alloc]init];
    
    _UUIDString = uuidString;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* strMacKey = [NSString stringWithFormat:@"kb_%@", uuidString];
    _mac = [defaults objectForKey:strMacKey];
    
    return self;
}

-(void)attach2Device:(CBPeripheral*) peripheral beaconMgr:(KBeaconsMgr*) beaconMgr
{
    _peripheral = peripheral;
    peripheral.delegate = self;
    mBeaconsMgr = beaconMgr;
    _UUIDString = peripheral.identifier.UUIDString;
}

-(NSArray*)allAdvPackets
{
    return mAdvPacketMgr.advPackets;
}

-(KBAdvPacketBase*)getAdvPacketByType:(KBAdvType) advType
{
    return [mAdvPacketMgr getAdvPacket:advType];
}

-(NSNumber*) maxTxPower
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.maxTxPower;
}

-(NSNumber*) minTxPower
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.minTxPower;
}

-(NSString*) model
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.model;
}

-(NSString*) version
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.version;
}

-(NSString*) hardwareVersion
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.hversion;
}

-(NSNumber*) capibility
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.basicCapibility;
}

-(NSNumber*) triggerCapibility
{
    KBCfgCommon* commCfg = (KBCfgCommon*)[mCfgMgr getConfigruationByType:KBConfigTypeCommon];
    return commCfg.trigCapibility;
}

-(NSNumber*)batteryPercent
{
    return mAdvPacketMgr.batteryPercent;
}

-(NSArray*) configParamaters
{
    return mCfgMgr.configParamaters;
}

-(KBCfgBase*)getConfigruationByType:(enum KBConfigType)type
{
    return (KBCfgBase*)[mCfgMgr getConfigruationByType:type];
}

-(void)setAdvTypeFilter:(NSNumber*)advTypeFilter
{
    mAdvPacketMgr.filterAdvType = advTypeFilter;
}

-(BOOL) parseAdvPacket:(NSDictionary*) advData rssi:(NSNumber*)rssi
{
    _isConnectable = ([advData objectForKey:@"kCBAdvDataIsConnectable"] > 0);
    
    _name = [advData objectForKey:@"kCBAdvDataLocalName"];
    
    _rssi = rssi;
    
    return [mAdvPacketMgr parseAdvPacket:advData rssi:rssi];
}

-(BOOL)isSensorDataSubscribe:(Class) sensorNtfMsgClass
{

    KBNotifyDataBase * notifyData = [[sensorNtfMsgClass alloc]init];
    KBSubscribeNotifyItem* notifyInstance = [notifyData2ClassMap objectForKey:[notifyData getSensorDataType]];

    return (notifyInstance != nil);
}

-(void)subscribeSensorDataNotify:(Class) sensorNtfMsgClass
                        delegate:(id<KBNotifyDataDelegate>) notifyDataCallback
                        callback:(onActionComplete)callback
{
    if (![self isSupportSensorDataNotification])
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device not support subscription", NSLocalizedDescriptionKey, @"device not support subscription", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgInputInvalid userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, error);
        }
        return;
    }

    KBNotifyDataBase* notifyData = [[sensorNtfMsgClass alloc]init];
    KBSubscribeNotifyItem* instance = [[KBSubscribeNotifyItem alloc]init];
    instance.notifyClass = sensorNtfMsgClass;
    instance.delegate = notifyDataCallback;
    instance.notifyType = [notifyData getSensorDataType];
    if (notifyData2ClassMap.count == 0)
    {
        if (mActionStatus != ACTION_IDLE)
        {
            if (callback != nil) {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device is busy", NSLocalizedDescriptionKey, @"device is busy", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
                callback(NO, error);
            }
            return;
        }
        
        if (_state != KBStateConnected)
        {
            if (callback != nil) {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device is not in connected", NSLocalizedDescriptionKey, @"device is not in connected", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
                callback(NO, error);
            }
            return;
        }

        //save callback
        mToAddedSubscribeInstance = instance;
        mEnableSubscribeNotifyCallback = callback;
        BOOL bResult = [self startEnableNotification: KB_CFG_SERVICES_UUID charUUID:KB_IND_CHAR_UUID on:YES];
        if (bResult)
        {
            [self startNewAction: ACTION_ENABLE_NTF timeout:3.0];
        }
        else
        {
            if (callback != nil)
            {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"enable notification failed", NSLocalizedDescriptionKey, @"enable notification failed", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
                callback(NO, error);
            }
        }
    }
    else
    {
        [notifyData2ClassMap setObject:instance forKey:instance.notifyType];
        if (callback != nil) {
            callback(YES, nil);
        }
    }
}

-(void)removeSubscribeSensorDataNotify:(Class)sensorNtfMsgClass callback:(onActionComplete) callback
{

    KBNotifyDataBase* notifyData = [[sensorNtfMsgClass alloc]init];
    NSNumber* notifyDataType = [notifyData getSensorDataType];
    if ([notifyData2ClassMap objectForKey: notifyDataType] != nil)
    {
        if (callback != nil) {
            callback(YES, nil);
        }
        return;
    }

    if (notifyData2ClassMap.count == 1)
    {
        if (mActionStatus != ACTION_IDLE)
        {
            NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device is busy", NSLocalizedDescriptionKey, @"device is busy", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
            callback(NO, error);
            return;
        }
        
        if (_state != KBStateConnected)
        {
            if (callback != nil) {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device is not in connected", NSLocalizedDescriptionKey, @"device is not in connected", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
                callback(NO, error);
            }
            return;
        }

        //save callback
        mToAddedSubscribeInstance = nil;
        mEnableSubscribeNotifyCallback = callback;
        if ([self startEnableNotification: KB_CFG_SERVICES_UUID charUUID:KB_IND_CHAR_UUID on:NO])
        {
            [self startNewAction:ACTION_ENABLE_NTF timeout:3.0];
        }
        
    } else {
        [notifyData2ClassMap removeObjectForKey:notifyDataType];
        if (callback != nil) {
            callback(YES, nil);
        }
    }
}

-(void) handleBeaconEnableSubscribeComplete
{
    [self cancelActionTimer];

    if (mToAddedSubscribeInstance != nil)
    {
        [notifyData2ClassMap setObject:mToAddedSubscribeInstance forKey:mToAddedSubscribeInstance.notifyType];
        mToAddedSubscribeInstance = nil;

        if (mEnableSubscribeNotifyCallback != nil)
        {
            onActionComplete tmpAction = mEnableSubscribeNotifyCallback;
            mEnableSubscribeNotifyCallback = nil;
            tmpAction(YES, nil);
        }
    }
    else
    {
        [notifyData2ClassMap removeAllObjects];
        if (mEnableSubscribeNotifyCallback != nil) {
            onActionComplete tmpAction = mEnableSubscribeNotifyCallback;
            mEnableSubscribeNotifyCallback = nil;
            tmpAction(YES, nil);
        }
    }
}

-(BOOL) connect:(NSString*)password timeout:(NSUInteger)timeout
{
    return [self connectEnhanced: password timeout:timeout para:nil];
}

-(BOOL) connectEnhanced:(NSString*)password timeout:(NSUInteger)timeout para:(KBConnPara* _Nullable) para
{
    if (_peripheral.state == CBPeripheralStateDisconnected
        && password.length >= 8 && password.length <= 16)
    {
        CBCentralManager* centralMgr = [mBeaconsMgr getBLECentralMgr];
        [centralMgr connectPeripheral:_peripheral options:nil];
        
        mPassword = password;
        [mAuthHandler setConnPara:para];
        _state = KBStateConnecting;
        
        //start connect timer
        if (mConnectingTimer != nil && mConnectingTimer.isValid)
        {
            [mConnectingTimer invalidate];
        }
        mConnectingTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(connectingTimeout:) userInfo:[NSNumber numberWithInteger:KBStateConnecting] repeats:NO];
        
        //cancel privous action
        [self cancelActionTimer];
        
        //notify connecting
        if (self.delegate != nil)
        {
            [self.delegate onConnStateChange:self state:KBStateConnecting evt:0];
        }
        
        return YES;
    }
    else
    {
        NSLog(@"device already connected");
        return NO;
    }
}

//connect device timeout
- (void) connectingTimeout:(NSTimer *)timer
{
    NSLog(@"Connecting to device timeout");
    [self closeBeacon:KBEvtConnTimeout];
}

//disconnecting timeout
- (void) disconnectingTimeout:(NSTimer *)timer
{
    NSLog(@"Disconnecting to device timeout");
    if (_state == KBStateDisconnecting)
    {
        _state = KBStateDisconnected;
        if (self.delegate != nil)
        {
            [self.delegate onConnStateChange:self state:_state evt:mCloseReason];
        }
    }
}

-(void) cancelActionTimer
{
    if (mActionTimer != nil && mActionTimer.isValid)
    {
        [mActionTimer invalidate];
    }
    mActionStatus = ACTION_IDLE;
}

-(BOOL) startNewAction:(int)nNewAction timeout:(NSUInteger)timeout
{
    if (mActionStatus != ACTION_IDLE)
    {
        NSLog(@"start new action failed during not idle");
        return NO;
    }
    
    mActionStatus = nNewAction;
    if (timeout > 0)
    {
        mActionTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(actionTimeout:) userInfo:[NSNumber numberWithInteger:KBStateConnecting] repeats:NO];
    }
    
    return YES;
}

//connect device timeout
- (void) actionTimeout:(NSTimer *)timer
{
    NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"msg timeout", NSLocalizedDescriptionKey, @"configruation command execute timeout", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
    NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgTimeout userInfo:userInfo1];
    
    if (mActionStatus == ACTION_INIT_READ_CFG)
    {
        mActionStatus = ACTION_IDLE;
        [self closeBeacon:KBEvtConnTimeout];
    }
    else if (mActionStatus == ACTION_USR_READ_CFG)
    {
        mActionStatus = ACTION_IDLE;
        if (mReadCfgCallback != nil)
        {
            onReadComplete tempCallback = mReadCfgCallback;
            mReadCfgCallback = nil;
            tempCallback(false, nil, error);
        }
    }
    else if (mActionStatus == ACTION_WRITE_CFG)
    {
        mActionStatus = ACTION_IDLE;
        if (mWriteCfgCallback != nil)
        {
            onActionComplete tempCallback = mWriteCfgCallback;
            mWriteCfgCallback = nil;
            tempCallback(false, error);
        }
    }
    else if (mActionStatus == ACTION_WRITE_CMD)
    {
        mActionStatus = ACTION_IDLE;
        if (mWriteCmdCallback != nil)
        {
            onActionComplete tempCallback = mWriteCfgCallback;
            mWriteCfgCallback = nil;
            tempCallback(false, error);
        }
    }
    else if (mActionStatus == ACTION_READ_SENSOR)
    {
        mActionStatus = ACTION_IDLE;
        if (mReadSensorCallback != nil)
        {
            onReadSensorComplete tempCallback = mReadSensorCallback;
            mReadSensorCallback = nil;
            tempCallback(false, nil, error);
        }
    }
    else if (mActionStatus == ACTION_ENABLE_NTF)
    {
        mActionStatus = ACTION_IDLE;
        if (mEnableSubscribeNotifyCallback != nil)
        {
            onActionComplete tempCallback = mEnableSubscribeNotifyCallback;
            mEnableSubscribeNotifyCallback = nil;
            tempCallback(false, error);
        }
    }
}

-(void) disconnect
{
    [self closeBeacon:KBEvtConnManualDisconnting];
    
    /*
    if (_peripheral.state == CBPeripheralStateConnecting
        || _peripheral.state == CBPeripheralStateConnected)
    {
        mCloseReason = KBEvtConnManualDisconnting;
        if (_state != KBStateDisconnecting)
        {
            _state = KBStateDisconnecting;
            [self.delegate connStateChange:self state:KBStateDisconnecting evt:mCloseReason];
        }
        
        CBCentralManager* centralMgr = [mBeaconsMgr getBLECentralMgr];
        [centralMgr cancelPeripheralConnection:_peripheral];
    }
    */
}

-(void)handleCentralBLEEvent:(CBPeripheralState)nNewState
{
    if (nNewState == CBPeripheralStateConnected)
    {
        if (self.state == KBStateConnecting)
        {
            _peripheral.delegate = self;
            [_peripheral discoverServices:nil];
        }
    }
    else if (nNewState == CBPeripheralStateDisconnected)
    {
        if (self.state == KBStateDisconnecting)
        {
            [self closeBeacon:mCloseReason];
        }
        else if (self.state == KBStateConnecting
                 || self.state == KBStateConnected)
        {
            [self closeBeacon:KBEvtConnException];
        }
    }
}

-(void)authStateChange:(KBAuthResult)authRslt
{
    if (authRslt == KBAuthFailed)
    {
        [self closeBeacon:KBEvtConnAuthFail];
    }
    else if (authRslt == KBAuthSuccess)
    {
        [self cancelActionTimer];
        
        //change to
        if (_state == KBStateConnecting)
        {
            int nReadCfgType = KBConfigTypeCommon |KBConfigTypeIBeacon | KBConfigTypeEddyURL | KBConfigTypeEddyUID |KBConfigTypeSensor;
            [self configReadBeaconParamaters:nReadCfgType type:ACTION_INIT_READ_CFG];
        }
    }
}

-(void)writeAuthData:(NSData*)data
{
    [self startWriteCfgValue:data];
}

-(void)closeBeacon:(int) errorReason
{
    mCloseReason = errorReason;
    
    //clear action timer
    [self cancelActionTimer];
    
    //cancel connecting timer
    if (_state == KBStateConnecting)
    {
        [mConnectingTimer invalidate];
    }
    if (_state == KBStateDisconnecting)
    {
        [mDisconntingTimer invalidate];
    }
    
    //cancel connect
    CBCentralManager* centralMgr = [mBeaconsMgr getBLECentralMgr];
    if (_peripheral.state == CBPeripheralStateConnecting
        || _peripheral.state == CBPeripheralStateConnected)
    {
        NSLog(@"Disconnecting kbeacon for reason:%d", errorReason);
        
        //start cancel connection
        [centralMgr cancelPeripheralConnection:_peripheral];
        
        //start disconn timer
        mDisconntingTimer = [NSTimer scheduledTimerWithTimeInterval:7.0 target:self selector:@selector(disconnectingTimeout:) userInfo:nil repeats:NO];
        
        //notify
        if (_state != KBStateDisconnecting)
        {
            _state = KBStateDisconnecting;
            [self.delegate onConnStateChange:self state:_state evt:mCloseReason];
        }
    }
    else
    {
        if (_state != KBStateDisconnected)
        {
            NSLog(@"Disconnected kbeacon for reason:%d", errorReason);
            _state = KBStateDisconnected;
            [self.delegate onConnStateChange:self state:_state evt:mCloseReason];
        }
    }
}

-(BOOL) startEnableNotification:(CBUUID*)srvUUID charUUID:(CBUUID*)charUUID on:(BOOL)bEnable
{
    CBService *cbService = [KBUtility findServiceFromUUID:_peripheral cbuuID:srvUUID];
    if (!cbService)
    {
        return NO;
    }
    
    //find characteristic from services
    CBCharacteristic *cbChar = [KBUtility findCharacteristicFromUUID:charUUID service:cbService];
    if (!cbChar)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@", cbChar.UUID.UUIDString, cbService.UUID.UUIDString);
        return NO;
    }
    
    //enable notification
    [_peripheral setNotifyValue:bEnable forCharacteristic:cbChar];
    
    return YES;
}

-(void) systemHandleResponse:(CBUUID*)cbUUID data:(Byte*)byRcvNtfValue lenght:(int)sysDataLen
{
    if ([cbUUID isEqual:KB_MAC_CHAR_UUID])
    {
        if (sysDataLen != 6 && sysDataLen != 8)
        {
            NSLog(@"mac address length error");
            [self closeBeacon: KBEvtConnServiceNotSupport];
            return;
        }
        
        if (sysDataLen == 8)
        {
            byRcvNtfValue[3] = byRcvNtfValue[5];
            byRcvNtfValue[4] = byRcvNtfValue[6];
            byRcvNtfValue[5] = byRcvNtfValue[7];
        }
        
        memcpy(mAuthDeviceMac, byRcvNtfValue, 6);
        _mac = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                byRcvNtfValue[5],
                byRcvNtfValue[4],
                byRcvNtfValue[3],
                byRcvNtfValue[2],
                byRcvNtfValue[1],
                byRcvNtfValue[0]];
        
        //save uuid and mac mapping
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString* strMacKey = [NSString stringWithFormat:@"kb_%@" ,_peripheral.identifier.UUIDString];
        [defaults setObject:self.mac forKey:strMacKey];
        
        //start auth entication
        if (_state == KBStateConnecting)
        {
            [self startEnableNotification: KB_CFG_SERVICES_UUID charUUID:KB_NTF_CHAR_UUID on:YES];
        }
    }
}

-(void) sendCommand:(NSDictionary*) cmdPara callback:(onActionComplete)callback
{
    NSError* error;
    
    if (mActionStatus != ACTION_IDLE)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device busy", NSLocalizedDescriptionKey, @"Last write or read action not complete", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
        callback(NO, error);
        return;
    }
    
    //save callback
    NSString* strJsonCfgData = [KBCfgHandler cmdParaToJsonString: cmdPara error:&error];
    if (strJsonCfgData == nil || strJsonCfgData.length == 0
        || error != nil)
    {
        if (callback != nil)
        {
            callback(NO, error);
        }
        return;
    }
    
    mToBeCfgData = nil;
    mWriteCmdCallback = callback;
    
    //get byte
    mByDownloadDatas = [strJsonCfgData dataUsingEncoding:NSUTF8StringEncoding];
    mByDownDataType = CENT_PERP_TX_JSON_DATA;
    
    //write data to kbeacon
    [self startNewAction:ACTION_WRITE_CMD timeout:MAX_READ_CFG_TIMEOUT];
    [self sendNextCfgData:0];
}


-(void) readConfig:(int) nConfigType callback:(onReadComplete)callback
{
    NSError* error;
    
    if (mActionStatus != ACTION_IDLE)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device busy", NSLocalizedDescriptionKey, @"Last write or read action not complete", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, nil, error);
        }
        return;
    }
    
    if (_state != KBStateConnected)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device state error", NSLocalizedDescriptionKey, @"device is not connected", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgStateError userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, nil, error);
        }
        return;
    }
    
    //save callback
    mReadCfgCallback = callback;
    if (![self configReadBeaconParamaters:nConfigType type: ACTION_USR_READ_CFG])
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"input paramaters error", NSLocalizedDescriptionKey, @"input paramaters error", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgInputInvalid userInfo:userInfo1];
        
        if (mReadCfgCallback != nil)
        {
            onReadComplete tempCallback = mReadCfgCallback;
            mReadCfgCallback = nil;
            tempCallback(NO, nil, error);
        }
    }
}

-(void)readConfigWithPara:(NSDictionary*) readCfgReq callback:(onReadComplete)callback
{
    NSError* error;
    
    if (mActionStatus != ACTION_IDLE)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device busy", NSLocalizedDescriptionKey, @"Last write or read action not complete", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
        
        if (callback != nil)
        {
            callback(NO, nil, error);
        }
        return;
    }
    
    if (_state != KBStateConnected)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device state error", NSLocalizedDescriptionKey, @"device is not connected", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgStateError userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, nil, error);
        }
        return;
    }
    
    //get configruation data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:readCfgReq options:NSJSONWritingPrettyPrinted error:&error];
    if (error || jsonData == nil || jsonData.length == 0)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"input paramaters error", NSLocalizedDescriptionKey, @"input paramaters error", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgInputInvalid userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, nil, error);
        }
        return;
    }
    
    mReadCfgCallback = callback;
    NSString* strJsonData = [KBUtility jsonData2StringWithoutSpaceReturn:jsonData];
    mByDownloadDatas = [strJsonData dataUsingEncoding:NSUTF8StringEncoding];
    mByDownDataType = CENT_PERP_TX_JSON_DATA;
    
    //start action
    [self startNewAction:ACTION_USR_READ_CFG timeout:MAX_READ_CFG_TIMEOUT];
    
    [self sendNextCfgData:0];
}

-(void) readTriggerConfig:(KBTriggerType) nTriggerType callback:(onReadComplete)callback
{
    //get configruation data
    NSDictionary *readCfgReq = @{JSON_MSG_TYPE_KEY:JSON_MSG_TYPE_GET_PARA,
                                 JSON_MSG_CFG_SUBTYPE:
                                     [NSNumber numberWithInt:KBConfigTypeTrigger],
                                 JSON_FIELD_TRIGGER_TYPE: [NSNumber numberWithLong:(long)nTriggerType]
                                 };
   [self readConfigWithPara:readCfgReq callback:^(BOOL bConfigSuccess, NSDictionary* __nullable readPara, NSError* _Nullable  error)
    {
        if (bConfigSuccess)
        {
            NSMutableArray* triggerCfgList = [[NSMutableArray alloc]init];
            NSArray* triggerList = [readPara objectForKey:@"trObj"];
            if (triggerList != nil)
            {
                for (int i = 0; i < triggerList.count; i++)
                {
                    NSDictionary* tmpTriggerCfg = [triggerList objectAtIndex:i];
                    KBCfgTrigger* cfgTrigger;
                    NSNumber* trType = [tmpTriggerCfg objectForKey:@"trType"];
                    if ([trType intValue] == KBTriggerTypeNearby)
                    {
                        cfgTrigger = [[KBCfgNearbyTrigger alloc]init];
                    }
                    else if ([trType intValue] == KBTriggerTypeHumidity)
                    {
                        cfgTrigger = [[KBCfgHumidityTrigger alloc]init];
                    }
                    else{
                        cfgTrigger = [[KBCfgTrigger alloc]init];
                    }
                    
                    [cfgTrigger updateConfig:tmpTriggerCfg];
                    
                    [triggerCfgList addObject:cfgTrigger];
                }
                
                NSDictionary* readTriggerData = @{@"trObj":triggerCfgList};
                
                if (callback != nil)
                {
                    callback(YES, readTriggerData, nil);
                }
            }
            else
            {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"configruation not supported", NSLocalizedDescriptionKey, @"configruation not supported", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgNotSupport userInfo:userInfo1];
                if (callback != nil)
                {
                    callback(NO, nil, error);
                }
            }
        }
        else
        {
            if (callback != nil)
            {
                callback(NO, nil, error);
            }
        }
    }];
}

-(void) modifyTriggerConfig:(KBCfgTrigger*) cfgTrigger callback:(onActionComplete)callback
{
    if (cfgTrigger.triggerAction == nil || cfgTrigger.triggerType == nil)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"paramaters is null", NSLocalizedDescriptionKey, @"paramaters is null", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgInputInvalid userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, error);
        }
        return;
    }
    
    NSArray<KBCfgBase*> *cfgList = [NSArray arrayWithObjects:cfgTrigger,nil];
    [self modifyConfig:cfgList callback:callback];
}

-(void) modifyConfig:(NSArray<KBCfgBase*>*) cfgPara callback:(onActionComplete)callback
{
    NSError* error;
    
    if (mActionStatus != ACTION_IDLE)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device busy", NSLocalizedDescriptionKey, @"Last write or read action not complete", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, error);
        }
        return;
    }
    if (_state != KBStateConnected)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device state error", NSLocalizedDescriptionKey, @"device is not connected", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgStateError userInfo:userInfo1];
        if (callback != nil)
        {
            callback(NO, error);
        }
        return;
    }
    
    //get configruation json
    NSString* strJson = [KBCfgHandler objectsToJsonString: cfgPara error:&error];
    if (error != nil || strJson == nil || strJson.length == 0)
    {
        if (callback != nil)
        {
            callback(NO, error);
        }
        return;
    }
    
    //save callback
    mWriteCfgCallback = callback;
    mToBeCfgData = cfgPara;
    mByDownloadDatas = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    mByDownDataType = CENT_PERP_TX_JSON_DATA;
    
    //write data to kbeacon
    [self startNewAction:ACTION_WRITE_CFG timeout:MAX_READ_CFG_TIMEOUT];
    [self sendNextCfgData:0];
}

-(void) sendSensorRequest:(NSData*)msgReq callback:(onReadSensorComplete)callback
{
    NSError* error;

   if (mActionStatus != ACTION_IDLE)
   {
       NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device busy", NSLocalizedDescriptionKey, @"Last write or read action not complete", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
       error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgBusy userInfo:userInfo1];
       if (callback != nil)
       {
           callback(NO,nil, error);
       }
       return;
   }
    
   if (_state != KBStateConnected)
   {
       NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"device state error", NSLocalizedDescriptionKey, @"device is not connected", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
       error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgStateError userInfo:userInfo1];
       if (callback != nil)
       {
           callback(NO, nil, error);
       }
       return;
   }

    if (msgReq == nil || msgReq.length == 0) {
       NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"input error", NSLocalizedDescriptionKey, @"input para is null", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
       error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgInputInvalid userInfo:userInfo1];
       if (callback != nil)
       {
           callback(NO, nil, error);
       }
       return;
   }

    mReadSensorCallback = callback;
    mByDownloadDatas = msgReq;
    mByDownDataType = CENT_PERP_TX_HEX_DATA;
    [self startNewAction: ACTION_READ_SENSOR timeout: MAX_READ_CFG_TIMEOUT];
    [self sendNextCfgData:0];
}

-(BOOL) sendNextCfgData:(int)nReqDataSeq
{
    if (mByDownloadDatas == nil || mByDownloadDatas.length == 0){
        NSLog(@"data not inited");
        return NO;
    }
    
    if (nReqDataSeq >= mByDownloadDatas.length)
    {
        NSLog(@"Tx config data complete");
        return YES;
    }
    
    //get mdu tag
    Byte nPduTag = PDU_TAG_START;
    int nMaxTxDataSize = [mAuthHandler.mtuSize intValue] - MSG_PDU_HEAD_LEN;
    int nDataLen = nMaxTxDataSize;
    if (mByDownloadDatas.length <= nMaxTxDataSize)
    {
        nPduTag = PDU_TAG_SINGLE;
        nDataLen = (int)mByDownloadDatas.length;
    }
    else if (nReqDataSeq == 0)
    {
        nPduTag = PDU_TAG_START;
        nDataLen = nMaxTxDataSize;
    }
    else if (nReqDataSeq + nMaxTxDataSize < mByDownloadDatas.length)
    {
        nPduTag = PDU_TAG_MIDDLE;
        nDataLen = nMaxTxDataSize;
    }
    else if (nReqDataSeq + nMaxTxDataSize >= mByDownloadDatas.length)
    {
        nPduTag = PDU_TAG_END;
        nDataLen = (int)mByDownloadDatas.length - nReqDataSeq;
    }
    
    //down data head
    NSMutableData* downData = [[NSMutableData alloc]init];
    Byte byAduTag = (mByDownDataType << 4) + nPduTag;
    [downData appendBytes:&byAduTag length:1];
    short nNetOrderSeq = htons(nReqDataSeq);
    [downData appendBytes:&nNetOrderSeq length:2];
    
    //fill body data
    NSRange range = NSMakeRange(nReqDataSeq, nDataLen);
    NSData* body = [mByDownloadDatas subdataWithRange:range];
    [downData appendData: body];
    
    //write data to device
    if (![self startWriteCfgValue:downData])
    {
        return NO;
    }
    
    return YES;
}

-(void) configHandleDownCmdAck:(Byte)framType dataType:(Byte)dataType data:(Byte*)data lenght:(int)dataLen
{
    short nReqDataSeq = ntohs(*(short*)&data[0]);
    short AckCause = ntohs(*(short*)&data[4]);
    NSError* error;
    
    if (AckCause == BEACON_ACK_CAUSE_CMD_RCV)
    {
        NSLog(@"download command to beacon(%@) success, wait execute",
        self.mac);
        if (ACTION_READ_SENSOR == mActionStatus && dataType == PERP_CENT_TX_HEX_ACK)
        {
            if (dataLen > DATA_ACK_HEAD_LEN)
            {
                mReceiveData = [[NSMutableData alloc]initWithCapacity:MAX_BUFFER_DATA_SIZE];
                
                [mReceiveData appendBytes:&data[DATA_ACK_HEAD_LEN]
                                   length:dataLen - DATA_ACK_HEAD_LEN];
                
                //inbound data, send report Ack
                [self configSendDataRptAck: mReceiveData.length dataType:CENT_PERP_DATA_RPT_ACK cause: 0];
            }
        }
    }
    else if(AckCause == BEACON_ACK_SUCCESS)
    {
        if (ACTION_WRITE_CFG == mActionStatus)
        {
            [self cancelActionTimer];
            
            //update config to local
            if (mToBeCfgData != nil)
            {
                [mCfgMgr updateConfig:mToBeCfgData];
            }
            
            //downloa data command complete
            if (mWriteCfgCallback != nil)
            {
                onActionComplete tempCallback = mWriteCfgCallback;
                mWriteCfgCallback = nil;
                tempCallback(YES, nil);
            }
        }
        else if (ACTION_WRITE_CMD == mActionStatus)
        {
            [self cancelActionTimer];
            
            if (mWriteCmdCallback != nil)
            {
                onActionComplete tempCallback = mWriteCmdCallback;
                mWriteCmdCallback = nil;
                tempCallback(YES, nil);
            }
        }
        else if (ACTION_READ_SENSOR == mActionStatus)
        {
            [self cancelActionTimer];
            
            if (dataLen > DATA_ACK_HEAD_LEN)
            {
                mReceiveData = [[NSMutableData alloc]initWithCapacity:MAX_BUFFER_DATA_SIZE];
                
                [mReceiveData appendBytes:&data[DATA_ACK_HEAD_LEN]
                                   length:dataLen - DATA_ACK_HEAD_LEN];
                
            }
            if (mReadSensorCallback != nil)
            {
                onReadSensorComplete readCallback = mReadSensorCallback;
                mReadSensorCallback = nil;
                if (mReceiveData.length > 0){
                    readCallback(true, mReceiveData, nil);
                }else{
                    readCallback(true, nil, nil);
                }
            }
        }
    }
    else if (AckCause == BEACON_ACK_EXPECT_NEXT)
    {
        if (ACTION_IDLE != mActionStatus)
        {
            [self sendNextCfgData:nReqDataSeq];
        }
    }
    else if (AckCause == BEACON_ACK_CMD_CMP)
    {
        NSLog(@"command execute complete");
    }
    else
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"download data complete", NSLocalizedDescriptionKey, @"Last write command failed", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,
            [NSNumber numberWithInt:AckCause],@"code", nil];
        
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (ACTION_INIT_READ_CFG == mActionStatus)
        {
            [self cancelActionTimer];

            [self closeBeacon:KBEvtConnException];
        }
        else if (ACTION_WRITE_CFG == mActionStatus)
        {
            [self cancelActionTimer];
            
            if (mWriteCfgCallback != nil)
            {
                onActionComplete tempCallback = mWriteCfgCallback;
                mWriteCfgCallback = nil;
                tempCallback(NO, error);
            }
        }
        else if (ACTION_WRITE_CMD == mActionStatus)
        {
            [self cancelActionTimer];
            
            if (mWriteCmdCallback != nil)
            {
                onActionComplete tempCallback = mWriteCmdCallback;
                mWriteCmdCallback = nil;
                
                tempCallback(NO, error);
            }
        }
        else if (ACTION_USR_READ_CFG == mActionStatus)
        {
            [self cancelActionTimer];
            
           if (mReadCfgCallback != nil)
           {
               onReadComplete tempCallback = mReadCfgCallback;
               mReadCfgCallback = nil;
               tempCallback(NO, nil, error);
           }
        }
        else if (ACTION_READ_SENSOR == mActionStatus)
        {
            [self cancelActionTimer];
            
            if (mReadSensorCallback != nil)
            {
                onReadSensorComplete tempCallback = mReadSensorCallback;
                mReadSensorCallback = nil;
                tempCallback(NO, nil, error);
            }
        }
    }
}

-(void)handleBeaconIndData:(NSData*)data
{
    if (data.length <= 1)
    {
        return;
    }
    
    const Byte* pNotifyData = [data bytes];
    int nDataType = pNotifyData[0];
    KBSubscribeNotifyItem* sensorInstance = [notifyData2ClassMap objectForKey:[NSNumber numberWithInt:nDataType]];
    if (sensorInstance == nil)
    {
        return;
    }
    
    KBNotifyDataBase * notifyData = [[sensorInstance.notifyClass alloc]init];
    [notifyData parseSensorDataResponse:self data:data];
    if (sensorInstance.delegate != nil)
    {
        [sensorInstance.delegate onNotifyDataReceived:self type:nDataType data:notifyData];
    }
}

-(void) configHandleReadDataRpt:(Byte)frameType dataType:(Byte)dataType data:(Byte*)data lenght:(int)dataLen
{
    BOOL bRcvDataCmp = NO;
    Byte* pRcvDataRpt = data;
    short nDataSeq = ntohs(*(short*)pRcvDataRpt);
    pRcvDataRpt += 2;
    dataLen -= 2;
    
    //frame start
    if (frameType == PDU_TAG_START)
    {
        //new read configruation
        mReceiveData = [[NSMutableData alloc]initWithCapacity:MAX_BUFFER_DATA_SIZE];
        
        //append data
        [mReceiveData appendBytes:pRcvDataRpt length:dataLen];
        
        //ack
        [self configSendDataRptAck: mReceiveData.length dataType:dataType cause: 0];
    }
    else if (frameType == PDU_TAG_MIDDLE)
    {
        if (nDataSeq != mReceiveData.length
            || mReceiveData.length + dataLen > MAX_BUFFER_DATA_SIZE)
        {
            [self configSendDataRptAck: mReceiveData.length dataType:dataType cause: 0x1];
        }
        else
        {
            [mReceiveData appendBytes:pRcvDataRpt length:dataLen];
            [self configSendDataRptAck: mReceiveData.length dataType:dataType cause: 0];
        }
    }
    else if (frameType == PDU_TAG_END)
    {
        if (nDataSeq != mReceiveData.length)
        {
            [self configSendDataRptAck: mReceiveData.length dataType:dataType cause: 0x1];
        }
        else
        {
            [mReceiveData appendBytes:pRcvDataRpt length:dataLen];
            [self configSendDataRptAck: mReceiveData.length dataType:dataType cause: 0];
            bRcvDataCmp = YES;
        }
    }
    else if (frameType == PDU_TAG_SINGLE)
    {
        //new read message command
        mReceiveData = [[NSMutableData alloc]initWithCapacity:500];
        [mReceiveData appendBytes:pRcvDataRpt length:dataLen];
        //[self configSendDataRptAck: mReceiveData.length dataType:dataType  cause: 0];
        bRcvDataCmp = YES;
    }
    
    if (bRcvDataCmp)
    {
        if (dataType == PERP_CENT_DATA_RPT)
        {
            [self handleJsonRptDataComplete];
        }
        else if (dataType == PERP_CENT_HEX_DATA_RPT)
        {
            [self handleHexRptDataComplete];
        }
    }
}

-(void)configSendDataRptAck:(short)ackDataSeq dataType:(Byte)dataType cause:(short)cause
{
    NSMutableData* ackDataBuff = [[NSMutableData alloc]initWithCapacity:20];
    
    //ack head
    Byte byAckHead = dataType << 4;
    byAckHead += PDU_TAG_SINGLE;
    [ackDataBuff appendBytes:&byAckHead length:1];
    
    //ack seq
    ackDataSeq = htons(ackDataSeq);
    [ackDataBuff appendBytes:&ackDataSeq length:2];
    
    //windows
    short window = 1000;
    window = htons(window);
    [ackDataBuff appendBytes:&window length:2];
    
    //cause
    cause = htons(cause);
    [ackDataBuff appendBytes:&cause length:2];
    
    [self startWriteCfgValue:ackDataBuff];
}

-(void)handleHexRptDataComplete
{
    if (mActionStatus == ACTION_READ_SENSOR)
    {
        [self cancelActionTimer];
        
        if (mReadSensorCallback != nil)
        {
            onReadSensorComplete tempCallback = mReadSensorCallback;
            mReadSensorCallback = nil;
            tempCallback(true, mReceiveData, nil);
        }
    }
}

-(BOOL)isSupportSensorDataNotification
{
    CBService *cbService = [KBUtility findServiceFromUUID:_peripheral cbuuID:KB_CFG_SERVICES_UUID];
    if (!cbService)
    {
        return NO;
    }
    
    CBCharacteristic *cbChar = [KBUtility findCharacteristicFromUUID:KB_IND_CHAR_UUID service:cbService];
    if (!cbChar)
    {
        return NO;
    }
    
    return YES;
}

-(void)handleJsonRptDataComplete
{
    NSDictionary *dictRcvData = [NSJSONSerialization JSONObjectWithData:mReceiveData options:kNilOptions error:nil];
    if(dictRcvData == nil)
    {
        NSLog(@"Parse Json response failed");
        if (mActionStatus == ACTION_INIT_READ_CFG)
        {
            [self closeBeacon:KBEvtConnException];
        }
        else if (mActionStatus == ACTION_USR_READ_CFG)
        {
            [self cancelActionTimer];
            
            if (mReadCfgCallback != nil)
            {
                NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"read data fail", NSLocalizedDescriptionKey, @"read data is null", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgReadNull userInfo:userInfo1];
                
                onReadComplete tempCallback = mReadCfgCallback;
                mReadCfgCallback = nil;
                tempCallback(false, nil, error);
            }
        }
    }
    else
    {
        //check if is connecting
        if (mActionStatus == ACTION_INIT_READ_CFG)
        {
            //invalid connection timer
            [mConnectingTimer invalidate];
            
            //cancel action timer
            [self cancelActionTimer];
            
            //get configruation
            [mCfgMgr initConfigFromJsonDicts:dictRcvData];
            
            //change connection state
            if ([self isSupportSensorDataNotification] && notifyData2ClassMap.count > 0)
            {
                [self startEnableNotification: KB_CFG_SERVICES_UUID charUUID:KB_IND_CHAR_UUID on:YES];
            }else{
                NSLog(@"Connect and initial KBeacon(%@) success", _mac);
                _state = KBStateConnected;
                [self.delegate onConnStateChange:self state:KBStateConnected evt:KBEvtConnSuccess];
            }
        }
        else if (mActionStatus == ACTION_USR_READ_CFG)
        {
            [self cancelActionTimer];

            if (mReadCfgCallback != nil)
            {
                onReadComplete tempCallback = mReadCfgCallback;
                mReadCfgCallback = nil;
                tempCallback(true, dictRcvData,nil);
            }
        }
        else
        {
            [self cancelActionTimer];
            NSLog(@"Unknown message receive");
        }
    }
}

-(BOOL) configReadBeaconParamaters:(int)nReadCfgType type:(int)nActionType
{
    NSError *error;
    if (ACTION_IDLE != mActionStatus)
    {
        NSLog(@"Last action command not complete");
        return NO;
    }
    
    //get configruation data
    NSDictionary *readCfgReq = @{JSON_MSG_TYPE_KEY:JSON_MSG_TYPE_GET_PARA,
                                 JSON_MSG_CFG_SUBTYPE: [NSNumber numberWithInt:nReadCfgType]
                                 };
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:readCfgReq options:NSJSONWritingPrettyPrinted error:&error];
    if (!error)
    {
        NSString* strJsonCfg = [KBUtility jsonData2StringWithoutSpaceReturn:jsonData];
        
        mByDownloadDatas = [strJsonCfg dataUsingEncoding:NSUTF8StringEncoding];
        mByDownDataType = CENT_PERP_TX_JSON_DATA;
        
        //start action
        [self startNewAction:nActionType timeout:MAX_READ_CFG_TIMEOUT];
        
        [self sendNextCfgData:0];
        
        return YES;
    }
    else
    {
        return NO;
    }
}


//write configruation to beacon
-(BOOL) startWriteCfgValue:(NSData *)data
{
    //get srv
    CBService *cbService = [KBUtility findServiceFromUUID:_peripheral cbuuID:KB_CFG_SERVICES_UUID];
    if (!cbService)
    {
        return NO;
    }
    CBCharacteristic *cbChar = [KBUtility findCharacteristicFromUUID:KB_WRITE_CHAR_UUID service:cbService];
    if (!cbChar)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@\r\n",cbService.UUID.UUIDString, cbChar.UUID.UUIDString, _peripheral.identifier.UUIDString);
        return NO;
    }
    
    //get write type
    CBCharacteristicWriteType writeType = CBCharacteristicWriteWithResponse;
    if ((CBCharacteristicPropertyWriteWithoutResponse & cbChar.properties) > 0){
        writeType = CBCharacteristicWriteWithoutResponse;
    }else if ((CBCharacteristicPropertyWrite & cbChar.properties) > 0){
        writeType = CBCharacteristicWriteWithResponse;
    }
    
    [_peripheral writeValue:data forCharacteristic:cbChar type:writeType];
    
    return YES;
}




-(BOOL) startReadCharatics: (CBUUID*)serviceUUID charUUID:(CBUUID*)charUUID
{
    CBService *cbService = [KBUtility findServiceFromUUID:_peripheral cbuuID:serviceUUID];
    if (!cbService) {
        return NO;
    }
    
    CBCharacteristic *cbCharacteristic = [KBUtility findCharacteristicFromUUID:charUUID service:cbService];
    if (!cbCharacteristic) {
        return NO;
    }
    
    //read value
    [_peripheral readValueForCharacteristic:cbCharacteristic];
    return YES;
}

//discover device
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristicsForService failed, uuid:%@", peripheral.identifier.UUIDString);
        
        [self closeBeacon:KBEvtConnException];
        return;
    }
    
    //discover characteristic
    for (int i=0; i < peripheral.services.count; i++)
    {
        CBService *service = [peripheral.services objectAtIndex:i];
        if ([service.UUID isEqual: KB_SYSTEM_SERVICE_UUID])
        {
            [_peripheral discoverCharacteristics:nil forService:service];
        }
        else if ([service.UUID isEqual: KB_CFG_SERVICES_UUID])
        {
            [_peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

//discover characteristic
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristicsForService failed, uuid:%@, srvID:%@",
              peripheral.identifier.UUIDString, service.UUID.UUIDString);
        
        //send close notify
        [self closeBeacon:KBEvtConnException];
        return;
    }
    
    if ([service.UUID isEqual:KB_SYSTEM_SERVICE_UUID])
    {
        //read mac address
        [self startReadCharatics:service.UUID charUUID:KB_MAC_CHAR_UUID];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error)
    {
        NSLog(@"didUpdateNotificationStateForCharacteristic failed, uuid:%@, srvID:%@, charID:%@",
              peripheral.identifier.UUIDString,
              characteristic.service.UUID.UUIDString,
              characteristic.UUID.UUIDString);
        
        [self closeBeacon: KBEvtConnException];
        return;
    }
    
    //start authentication
    if ([characteristic.UUID isEqual:KB_NTF_CHAR_UUID])
    {
        if (_state == KBStateConnecting)
        {
            [mAuthHandler authSendMd5Request:self.mac password:mPassword];
        }
    }
    else if ([characteristic.UUID isEqual:KB_IND_CHAR_UUID])
    {
        if (_state == KBStateConnecting)
        {
            NSLog(@"Connect and initial KBeacon(%@) success", _mac);
            _state = KBStateConnected;
            [self.delegate onConnStateChange:self state:KBStateConnected evt:KBEvtConnSuccess];
        }
        else
        {
            [self handleBeaconEnableSubscribeComplete];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [self closeBeacon:KBEvtConnException];
        return;
    }

    //handle notify data
    if ([characteristic.UUID isEqual: KB_MAC_CHAR_UUID])
    {
        //read data
        Byte byRcvNtfValue[MAX_BLE_MTU_SIZE] = {0};
        int nRcvDataLen = (int)characteristic.value.length;
        [characteristic.value getBytes:byRcvNtfValue length:nRcvDataLen];
        
        //handle read mac address
        [self systemHandleResponse:characteristic.UUID data:byRcvNtfValue lenght:nRcvDataLen];
    }
    else if ([characteristic.UUID isEqual: KB_NTF_CHAR_UUID])
    {
        //read data
        Byte byRcvNtfValue[MAX_BLE_MTU_SIZE] = {0};
        int nRcvDataLen = (int)characteristic.value.length;
        [characteristic.value getBytes:byRcvNtfValue length:nRcvDataLen];
        
        //handle notify data
        Byte byDataType = (byRcvNtfValue[0] >> 4) & 0xF;
        Byte byFrameType = (byRcvNtfValue[0] & 0xF);
        if (byDataType == DATA_TYPE_AUTH)
        {
            [mAuthHandler authHandleResponse:&byRcvNtfValue[1] lenght:nRcvDataLen-1];
        }
        else if (byDataType == PERP_CENT_TX_JSON_ACK || byDataType == PERP_CENT_TX_HEX_ACK)
        {
            [self configHandleDownCmdAck:byFrameType dataType:byDataType data:&byRcvNtfValue[1] lenght:nRcvDataLen-1];
        }
        else if (byDataType == PERP_CENT_DATA_RPT
                 || byDataType == PERP_CENT_HEX_DATA_RPT)
        {
            [self configHandleReadDataRpt:byFrameType dataType:byDataType data:&byRcvNtfValue[1] lenght:nRcvDataLen-1];
        }
    }
    else if ([characteristic.UUID isEqual: KB_IND_CHAR_UUID])
    {
        //handle notify data
        [self handleBeaconIndData:characteristic.value];
    }
}


@end
