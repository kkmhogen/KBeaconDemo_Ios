//
//  BeaconDevice.h
//  ESLConfig
//
//  Created by kkm on 2018/12/8.
//  Copyright © 2018 kkm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import <KBAdvPacketBase.h>
#import <KBAuthHandler.h>
#import <KBCfgCommon.h>
#import <KBCfgIBeacon.h>
#import <KBCfgEddyUID.h>
#import <KBCfgEddyURL.h>
#import <KBCfgSensor.h>
#import <KBException.h>
#import <KBCfgTrigger.h>
#import <KBNotifyDataBase.h>
#import <KBSubscribeNotifyItem.h>

NS_ASSUME_NONNULL_BEGIN

//connect status
typedef NS_ENUM(NSInteger, KBConnState)
{
    KBStateDisconnected = 0,
    KBStateConnecting,
    KBStateDisconnecting,
    KBStateConnected
};

//connection event
typedef NS_ENUM(NSInteger, KBConnEvtReason)
{
    KBEvtConnSuccess = 0,
    KBEvtConnTimeout,
    KBEvtConnException,
    KBEvtConnServiceNotSupport,
    KBEvtConnManualDisconnting,
    KBEvtConnAuthFail,
};


@class KBeacon;
@protocol ConnStateDelegate<NSObject>
-(void)onConnStateChange:(KBeacon*)beacon state:(KBConnState)state evt:(KBConnEvtReason)evt;
@end

//read config data callback
typedef void (^onReadComplete)(BOOL bConfigSuccess, NSDictionary* __nullable readPara, NSError* _Nullable  error);

//read sensor data callback
typedef void (^onReadSensorComplete)(BOOL bConfigSuccess, NSData* _Nullable data, NSError* _Nullable  error);

//action complete
typedef void (^onActionComplete)(BOOL bConfigSuccess, NSError* _Nullable error);

//declare
@class KBeaconsMgr;
@class KBAdvPacketBase;

//beacon device
@interface KBeacon : NSObject<CBPeripheralDelegate, KBAuthDelegate>

@property(nonatomic,weak)id<ConnStateDelegate> delegate;

@property (strong) CBPeripheral* peripheral;

//adv information
@property (strong, readonly) NSString* mac;

@property (strong, readonly) NSString* UUIDString;

@property (assign, readonly) BOOL isConnectable;

@property (strong, readonly) NSString* name;

@property (strong, readonly) NSNumber* rssi;

@property (strong, readonly) NSNumber* batteryPercent;

//device state
@property (assign, readonly) KBConnState state;

///////////////////////////////////////
//all adv packets
@property (weak, readonly) NSArray* allAdvPackets;

//get advitisement packet by type
-(KBAdvPacketBase*)getAdvPacketByType:(KBAdvType) advType;


//////////////////////////////configuration about beacon
@property(weak, readonly)NSNumber* maxTxPower;

@property(weak, readonly)NSNumber* minTxPower;

//device model
@property (strong, readonly) NSString* model;

//device version
@property (strong, readonly) NSString* version;

//device hardware version
@property (strong, readonly) NSString* hardwareVersion;

//basic capibility
@property (strong, readonly) NSNumber* capibility;

//trigger capibility
@property (strong, readonly) NSNumber* triggerCapibility;

//all configruation paramaters
@property (weak, readonly) NSArray* configParamaters;

//get configruation by type
-(KBCfgBase*)getConfigruationByType:(KBConfigType)type;

//////////////////////////////////////////////
-(id) initWithUUID:(NSString*)uuidString;

//connect to device
-(BOOL) connect:(NSString*)password timeout:(NSUInteger)timeout;

//connect to device with para
-(BOOL) connectEnhanced:(NSString*)password timeout:(NSUInteger)timeout para:(KBConnPara* _Nullable)para;

//close bluetooth connection
-(void) disconnect;

//config beacon paramaters to device
-(void) modifyConfig:(NSArray<KBCfgBase*>*) cfgPara callback:(onActionComplete)callback;

//read trigger configruation from device
-(void) readTriggerConfig:(KBTriggerType) nTriggerType callback:(onReadComplete)callback;

//config beacon trigger paramaters to device
-(void) modifyTriggerConfig:(KBCfgTrigger*) cfgTrigger callback:(onActionComplete)callback;

//read config from device
-(void)readConfigWithPara:(NSDictionary*) readCfgReq callback:(onReadComplete)callback;

//read senor data
-(void) sendSensorRequest:(NSData*)msgReq callback:(onReadSensorComplete)callback;

//set adv type filter
-(void)setAdvTypeFilter:(NSNumber*)advTypeFilter;

//send commond to device
-(void) sendCommand:(NSDictionary*) cmdPara callback:(onActionComplete)callback;

//add notify data subscriber
-(void)subscribeSensorDataNotify:(Class) sensorNtfMsgClass
                        delegate:(id<KBNotifyDataDelegate>) notifyDataCallback
                        callback:(onActionComplete)callback;

//check if sensor data subscribed
-(BOOL)isSensorDataSubscribe:(Class) sensorNtfMsgClass;

/////////////////////////////////////////
-(void)attach2Device:(CBPeripheral*) peripheral beaconMgr:(KBeaconsMgr*) beaconMgr;

-(BOOL) parseAdvPacket:(NSDictionary*) advData rssi:(NSNumber*)rssi;

-(void) handleCentralBLEEvent:(CBPeripheralState)nNewState;

-(BOOL)isSupportSensorDataNotification;

@end

NS_ASSUME_NONNULL_END
