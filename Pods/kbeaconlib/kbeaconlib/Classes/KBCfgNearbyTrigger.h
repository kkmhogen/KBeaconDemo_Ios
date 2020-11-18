//
//  KBCfgNearbyTrigger.h
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <KBCfgTrigger.h>
#import <KBCfgSleepTime.h>

NS_ASSUME_NONNULL_BEGIN

#define String LOG_TAG @"KBCfgNearbyTrigger"
#define ALM_DISTANCE_NEAY 13
#define ALM_DISTANCE_MIDDLE 20
#define ALM_DISTANCE_FARWAY 35

#define JSON_FIELD_NEARBY_SCAN_INTERVAL @"nSTvl"
#define JSON_FIELD_NEARBY_SCAN_WINDOW @"nSWin"
#define JSON_FIELD_NEARBY_ADV_TX_PWR @"nAdPwr"
#define JSON_FIELD_NEARBY_ADV_INTERVAL @"nAdTvl"
#define JSON_FIELD_NEARBY_ALM_INTERVAL @"nAlTvl"
#define NEARBY_ALM_WINDOW @"nAlWin"
#define JSON_FIELD_NEARBY_ALM_FACTORY @"nAlFt"
#define JSON_FIELD_NEARBY_ALM_DISTANCE @"nAlDs"
#define JSON_FIELD_NEARBY_SLEEP_TIME @"nSTm"


@interface KBCfgNearbyTrigger : KBCfgTrigger
@property (strong, nonatomic) NSNumber* nbScanInterval;

@property (strong, nonatomic) NSNumber* nbScanWindow;

@property (strong, nonatomic) NSNumber* nbAdvTxPower;

@property (strong, nonatomic) NSNumber* nbAdvInterval;

@property (strong, nonatomic) NSNumber* nbALmInterval;

@property (strong, nonatomic) NSNumber* nbALmDuration;

@property (strong, nonatomic) NSNumber* nbAlmFactory;

@property (strong, nonatomic) NSNumber* nbAlmDistance;

-(KBCfgSleepTime*) getNbSleepLocalTime;

-(KBCfgSleepTime*) getNbSleepUtcTime;

-(void) setNbSleepLocalTime:(KBCfgSleepTime*) sleepTime;

-(void) setNbSleepUtcTime:(KBCfgSleepTime*) sleepTime;


@end

NS_ASSUME_NONNULL_END
