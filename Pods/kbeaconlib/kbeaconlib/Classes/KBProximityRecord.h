//
//  KBProximityRecord.h
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBProximityRecord : NSObject

//adv information
@property (strong) NSString* mac;

@property (strong) NSNumber* nearbyTime;

@property (strong) NSNumber* majorID;

@property (strong) NSNumber* minorID;

@property (strong) NSNumber* utcTime;


@end

NS_ASSUME_NONNULL_END
