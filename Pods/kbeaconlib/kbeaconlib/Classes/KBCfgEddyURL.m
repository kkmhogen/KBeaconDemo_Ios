//
//  KBCfgEddyURL.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/28.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBCfgEddyURL.h"
#import "KBException.h"

@implementation KBCfgEddyURL

-(KBConfigType) cfgParaType
{
    return KBConfigTypeEddyURL;
}

-(void)setUrl:(NSString*) url
{
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (url.length >= 3)
    {
        _url = url;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"eddystone url invalid"];
    }
}

-(int) updateConfig:(NSDictionary*)dicts
{
    if ([dicts objectForKey:JSON_FIELD_EDDY_URL_ADDR] != nil)
    {
        _url = [dicts objectForKey:JSON_FIELD_EDDY_URL_ADDR];
        return 1;
    }
    
    return 0;
}

-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary*cfgDicts = [[NSMutableDictionary alloc]init];
    
    if (_url != nil)
    {
        [cfgDicts setObject:_url forKey:JSON_FIELD_EDDY_URL_ADDR];
    }
    
    return cfgDicts;
}

@end
