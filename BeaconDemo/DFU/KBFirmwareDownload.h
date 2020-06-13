//
//  KBFirmwareDownload.h
//  KBeacon
//
//  Created by hogen on 2020/6/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^onHttpFirmwareDataDownComplete)(BOOL bResult, NSURL* _Nullable url, NSError* _Nullable error);

typedef void (^onHttpFirmwareInfoDownCallback)(BOOL bResult, NSDictionary* _Nullable info, NSError* _Nullable error);


@interface KBFirmwareDownload : NSObject

@property (strong) NSString* firmwareWebAddress;

-(instancetype)init;

-(void) downloadFirmwareInfo:(NSString*)beaconModel callback:(onHttpFirmwareInfoDownCallback)callback;

-(void) downLoadFirmwreData:(NSString*) urlStr callback:(onHttpFirmwareDataDownComplete)callback;

@end

NS_ASSUME_NONNULL_END
