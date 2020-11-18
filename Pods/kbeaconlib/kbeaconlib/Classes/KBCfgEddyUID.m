//
//  KBCfgEddyUID.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/28.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBCfgEddyUID.h"
#import "KBException.h"

@implementation KBCfgEddyUID

-(KBConfigType) cfgParaType
{
    return KBConfigTypeEddyUID;
}

-(void)setNid:(NSString*) nid
{
    if (nid.length == 22 && [KBUtility isHexString:nid])
    {
        _nid = nid;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"eddystone namespace id invalid"];

    }
}

-(void)setSid:(NSString*) sid
{
    if (sid.length == 14 && [KBUtility isHexString:sid])
    {
        _sid = sid;
    }
    else
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"eddystone serial id invalid"];
    }
}


-(int) updateConfig:(NSDictionary*)dicts
{
    int nUpdatePara = 0;
    
    if ([dicts objectForKey:JSON_FIELD_EDDY_UID_NID] != nil)
    {
        _nid = [dicts objectForKey:JSON_FIELD_EDDY_UID_NID];
        nUpdatePara++;
    }
    
    if ([dicts objectForKey:JSON_FIELD_EDDY_UID_SID] != nil)
    {
        _sid = [dicts objectForKey:JSON_FIELD_EDDY_UID_SID];
        nUpdatePara++;
    }
    
    return nUpdatePara;
}

-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary*cfgDicts = [[NSMutableDictionary alloc]init];

    if (_nid != nil)
    {
        [cfgDicts setObject:_nid forKey:JSON_FIELD_EDDY_UID_NID];
    }
    
    if (_sid != nil)
    {
        [cfgDicts setObject:_sid forKey:JSON_FIELD_EDDY_UID_SID];
    }
    
    return cfgDicts;
}


@end
