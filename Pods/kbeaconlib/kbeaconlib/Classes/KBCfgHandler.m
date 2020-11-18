//
//  KBCfgManager.m
//  KBeaconConfig
//
//  Created by hogen on 2019/9/10.
//  Copyright © 2019 hogen. All rights reserved.
//

#import "KBCfgHandler.h"
#import "KBException.h"

static NSDictionary* kbCfgTypeObjects;

@implementation KBCfgHandler
{
    NSMutableDictionary* _kbCfgPara;
}

+(void)initialize
{
    kbCfgTypeObjects = @{
                         [NSString stringWithFormat:@"%ld",(long)KBConfigTypeIBeacon]:
                             KBCfgIBeacon.class,
                         [NSString stringWithFormat:@"%ld",(long)KBConfigTypeEddyUID]:
                             KBCfgEddyUID.class,
                         [NSString stringWithFormat:@"%ld",(long)KBConfigTypeEddyURL]:
                             KBCfgEddyURL.class,
                         [NSString stringWithFormat:@"%ld",(long)KBConfigTypeSensor]:
                             KBCfgSensor.class,
                         [NSString stringWithFormat:@"%ld",(long)KBConfigTypeCommon]:
                             KBCfgCommon.class,
                         [NSString stringWithFormat:@"%ld",(long)KBConfigTypeTrigger]:
                             KBCfgTrigger.class,
                         };
}

-(id)init
{
    self = [super init];
    
    _kbCfgPara = [[NSMutableDictionary alloc]init];
        
    return self;
}

-(void)initConfigFromJsonString:(NSString*) jsonMsg
{
    [_kbCfgPara removeAllObjects];
    
    NSArray* objects = [KBCfgHandler jsonStringToObjects:jsonMsg];
    if (objects != nil)
    {
        for (KBCfgBase* obj in objects)
        {
            NSString* strCfgPara = [NSString stringWithFormat:@"%ld", (long)obj.cfgParaType];
            [_kbCfgPara setObject:obj forKey:strCfgPara];
        }
    }
}

-(void)initConfigFromJsonDicts:(NSDictionary*) dictPara
{
    [_kbCfgPara removeAllObjects];
    
    NSArray* objects = [KBCfgHandler dictParaToObjects:dictPara];
    if (objects != nil)
    {
        for (KBCfgBase* obj in objects)
        {
            NSString* strCfgPara = [NSString stringWithFormat:@"%ld", (long)obj.cfgParaType];
            [_kbCfgPara setObject:obj forKey:strCfgPara];
        }
    }
}

-(KBCfgBase*)getConfigruationByType:(KBConfigType)type
{
    NSString* strCfgTypeKey = [NSString stringWithFormat:@"%ld", (long)type];
    
    return [_kbCfgPara objectForKey:strCfgTypeKey];
}

-(NSArray*) configParamaters
{
    if (_kbCfgPara == nil || _kbCfgPara.count == 0)
    {
        return nil;
    }
    
    return [_kbCfgPara allValues];
}


-(void)updateConfig:(NSArray<KBCfgBase*>*)newCfgArray
{
    NSError* error;
    
    for (KBCfgBase* obj in newCfgArray)
    {
        NSMutableDictionary* updatePara = [obj toDictionary];
        if (updatePara == nil || error != nil)
        {
            continue;
        }
        NSString* strCfgParaType = [NSString stringWithFormat:@"%ld", (long)obj.cfgParaType];
        KBCfgBase* kbCfgObj = [_kbCfgPara objectForKey:strCfgParaType];
        if (kbCfgObj == nil)
        {
            Class class = [kbCfgTypeObjects objectForKey:strCfgParaType];
            KBCfgBase* kbCfgBase = [[class alloc]init];
            [_kbCfgPara setValue:kbCfgBase forKey:strCfgParaType];
            
            [kbCfgBase updateConfig:updatePara];
        }
        else
        {
            [kbCfgObj updateConfig:updatePara];
        }
    }
}


//read json string to configruation
+(NSArray<KBCfgBase*>*)jsonStringToObjects:(NSString*)jsonMsg
{
    NSError *error = nil;
    NSData* jsonData = [jsonMsg dataUsingEncoding:NSASCIIStringEncoding];
    NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingAllowFragments
                                                                 error:&error];
    if (error != nil)
    {
        return nil;
    }
    
    return [KBCfgHandler dictParaToObjects:jsonObject];
}

+(NSArray<KBCfgBase*>*)dictParaToObjects:(NSDictionary*)dicts
{
    NSMutableArray<KBCfgBase*>* arrCfgList = [[NSMutableArray alloc]init];
    
    //read basic capibility
    NSNumber* cfgSubType = [dicts objectForKey:JSON_MSG_CFG_SUBTYPE];
    if (cfgSubType == nil)
    {
        return nil;
    }
    
    //check if need read adv type config
    int nCfgSubType = [cfgSubType intValue];
    for (NSString *keyCfgType in kbCfgTypeObjects)
    {
        if (([keyCfgType intValue] & nCfgSubType) > 0)
        {
            Class class = [kbCfgTypeObjects objectForKey:keyCfgType];
            KBCfgBase* kbCfgBase = [[class alloc]init];
            [kbCfgBase updateConfig:dicts];
            [arrCfgList addObject:kbCfgBase];
        }
    }
    
    return arrCfgList;
}

//parse command para to string
+(NSString*)cmdParaToJsonString:(NSDictionary*)paraDicts error:(NSError**)error
{
    if (paraDicts != nil)
    {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:paraDicts options:NSJSONWritingPrettyPrinted error:error];
        if (*error)
        {
            NSLog(@"command paras data to json failed");
            return nil;
        }
        
        NSString* strJsonString = [KBUtility jsonData2StringWithoutSpaceReturn:jsonData];
        return strJsonString;
    }
    
    return nil;
}

//translate object to json string for download to beacon
+(NSString*)objectsToJsonString:(NSArray<KBCfgBase*>*)cfgArray error:(NSError**)error
{
    NSMutableDictionary* paraDicts = [KBCfgHandler objectsToParaDict:cfgArray error:error];
    if (paraDicts != nil)
    {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:paraDicts options:NSJSONWritingPrettyPrinted error:error];
        if (*error)
        {
            NSLog(@"config data to json failed");
            return nil;
        }
        
        NSString* strJsonString = [KBUtility jsonData2StringWithoutSpaceReturn:jsonData];
        
        return strJsonString;
    }
    
    return nil;
}

+(NSMutableDictionary*)objectsToParaDict:(NSArray<KBCfgBase*>*)cfgArray error:(NSError**)error
{
    NSMutableDictionary* paraDicts = [[NSMutableDictionary alloc]init];
    int nCfgType = 0;
    
    for(KBCfgBase* obj in cfgArray)
    {
        nCfgType = (nCfgType | (int)obj.cfgParaType);
        NSDictionary* objPara = [obj toDictionary];
        if (objPara != nil)
        {
            [paraDicts addEntriesFromDictionary:objPara];
        }
    }
    
    //check if is no data need config
    if (paraDicts.count == 0)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"Empty configruation paramaters", NSLocalizedDescriptionKey, @"No paramaters need to be configed", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgNoParameters userInfo:userInfo1];
        return nil;
    }
    
    //add configruation type
    [paraDicts setObject:[NSNumber numberWithInt:nCfgType]
                  forKey:JSON_MSG_CFG_SUBTYPE];
    
    //config message
    [paraDicts setObject:JSON_MSG_TYPE_CFG
                  forKey:JSON_MSG_TYPE_KEY];
    
    return paraDicts;
}



@end
