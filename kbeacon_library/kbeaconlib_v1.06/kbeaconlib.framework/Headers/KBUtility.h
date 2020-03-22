//
//  KBUtility.h
//  KBeaconConfig
//
//  Created by KKM on 2017/7/14.
//  Copyright © 2019 KKM. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define PARCE_UUID_EDDYSTONE [CBUUID UUIDWithString:@"0000FEAA-0000-1000-8000-00805f9b34fb"]

#define PARCE_UUID_KB_EXT_DATA [CBUUID UUIDWithString:@"00002080-0000-1000-8000-00805f9b34fb"]


//configruation uuid for beacon
#define SRV_CFG_UUID_EDDYSTONE [CBUUID UUIDWithString:@"EE0C2080-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_LOCK_STATE_UUID [CBUUID UUIDWithString:@"EE0C2081-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_LOCK_UUID [CBUUID UUIDWithString:@"EE0C2082-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_UNLOCK_UUID [CBUUID UUIDWithString:@"EE0C2083-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_URI_DATA_UUID [CBUUID UUIDWithString:@"EE0C2084-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_ADV_FLAG_UUID [CBUUID UUIDWithString:@"EE0C2085-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_TX_POWER_LVLS_UUID [CBUUID UUIDWithString:@"EE0C2086-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_TX_POWER_IDX_UUID [CBUUID UUIDWithString:@"EE0C2087-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_ADV_PERIOD_UUID [CBUUID UUIDWithString:@"EE0C2088-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_RESET_UUID [CBUUID UUIDWithString:@"EE0C2089-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_IBEACON_DATA_UUID [CBUUID UUIDWithString:@"EE0C208A-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_UID_DATA_UUID [CBUUID UUIDWithString:@"EE0C208B-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_ADV_TYPE_UUID [CBUUID UUIDWithString:@"EE0C208C-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_DEV_NAME_UUID [CBUUID UUIDWithString:@"EE0C208D-8786-40BA-AB96-99B91AC981D8"]
#define CHR_CFG_MEASURE_PWR_UUID [CBUUID UUIDWithString:@"EE0C208E-8786-40BA-AB96-99B91AC981D8"]

//beacon system info
#define KB_SYSTEM_SERVICE_UUID [CBUUID UUIDWithString:@"0000180a-0000-1000-8000-00805f9b34fb"]
#define KB_MAC_CHAR_UUID [CBUUID UUIDWithString:@"00002a23-0000-1000-8000-00805f9b34fb"]
#define KB_MODEL_CHAR_UUID [CBUUID UUIDWithString:@"00002a24-0000-1000-8000-00805f9b34fb"]
#define KB_VER_CHAR_UUID [CBUUID UUIDWithString:@"00002a26-0000-1000-8000-00805f9b34fb"]

//beacon system info
#define KB_CFG_SERVICES_UUID [CBUUID UUIDWithString:@"0000FEA0-0000-1000-8000-00805f9b34fb"]
#define KB_WRITE_CHAR_UUID [CBUUID UUIDWithString:@"0000FEA1-0000-1000-8000-00805f9b34fb"]
#define KB_NTF_CHAR_UUID [CBUUID UUIDWithString:@"0000FEA2-0000-1000-8000-00805f9b34fb"]



#define ntohs(x)    __DARWIN_OSSwapInt16(x)
#define htons(x)    __DARWIN_OSSwapInt16(x)
#define ntohl(x)    __DARWIN_OSSwapInt32(x)
#define htonl(x)    __DARWIN_OSSwapInt32(x)

@interface KBUtility : NSObject

+(CBUUID*) CBUUID16ToCBUUID128:(CBUUID *)UUID16;

+(CBService *) findServiceFromUUID:(CBPeripheral*) periperial cbuuID: (CBUUID *)UUID;

+(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;

+(BOOL) isHexString:(NSString*)hexString;

+(BOOL) isUUIDString:(NSString*)hexString;

+(NSData*) hexStringToBytes: (NSString*) hexString;

+(NSString*)bytesToHexString:(NSData*)data;

+(NSString*)jsonData2StringWithoutSpaceReturn:(NSData*)jsonData;

+(NSString*) FormatHexUUID2User:(NSString*)strUUID;

@end

NS_ASSUME_NONNULL_END
