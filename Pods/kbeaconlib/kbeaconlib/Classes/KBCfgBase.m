//
//  KBAdvCfg.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/28.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBCfgBase.h"

#define JSON_FIELD_ADV_FLAG @"advFlag"


@implementation KBCfgBase

- (id)init
{
    self = [super init];
    return self;
}

-(KBConfigType) cfgParaType
{
    return KBConfigTypeInvalid;
}

-(int) updateConfig:(NSDictionary*)dicts
{
    return 0;
}

-(NSMutableDictionary*) toDictionary
{
    return nil;
}


@end
