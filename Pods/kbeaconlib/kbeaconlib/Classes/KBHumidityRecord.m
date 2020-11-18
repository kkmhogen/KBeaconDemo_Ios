//
//  KBHumidityRecord.m
//  KBeacon
//
//  Created by hogen on 2020/11/3.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBHumidityRecord.h"

@implementation KBHumidityRecord

-(id)init:(NSDictionary*)dicts
{
    self = [super init];
    [self fromDictory:dicts];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    //encode properties/values
    [aCoder encodeObject:self.utcTime      forKey:@"utc"];
    [aCoder encodeObject:self.temperature  forKey:@"temp"];
    [aCoder encodeObject:self.humidity      forKey:@"hum"];
}
 
-(id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super init]))
    {
        //decode properties/values
        self.utcTime       = [aDecoder decodeObjectForKey:@"utc"];
        self.temperature   = [aDecoder decodeObjectForKey:@"temp"];
        self.humidity       = [aDecoder decodeObjectForKey:@"hum"];
    }
 
    return self;
}

-(NSDictionary*) toDictory
{
    NSDictionary * dicts = @{@"utc":self.utcTime,
                             @"temp":self.temperature,
                             @"hum":self.humidity};
    
    return dicts;
}

-(void)fromDictory:(NSDictionary*)dicts
{
    self.utcTime = [dicts objectForKey:@"utc"];
    self.temperature = [dicts objectForKey:@"temp"];
    self.humidity = [dicts objectForKey:@"hum"];
}

@end
