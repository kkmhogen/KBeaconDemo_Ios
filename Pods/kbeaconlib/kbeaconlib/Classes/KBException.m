//
//  KBException.m
//  KBeaconConfig
//
//  Created by hogen on 2019/10/3.
//  Copyright © 2019 hogen. All rights reserved.
//

#import "KBException.h"

@implementation KBException

-(id) init:(NSInteger)code info:(NSString*)info
{
    self = [super initWithName:@"KBException" reason:info userInfo:nil];
    _errorCode = code;
    
    return self;
}


@end
