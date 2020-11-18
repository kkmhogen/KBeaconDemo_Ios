//
//  KBHumidityRecord.h
//  KBeacon
//
//  Created by hogen on 2020/11/3.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBHumidityRecord : NSObject<NSCoding>

@property (strong) NSNumber* utcTime;

@property (strong) NSNumber* temperature;

@property (strong) NSNumber* humidity;

-(id)init:(NSDictionary*)dicts;

-(NSDictionary*) toDictory;

-(void)fromDictory:(NSDictionary*)dicts;

@end

NS_ASSUME_NONNULL_END
