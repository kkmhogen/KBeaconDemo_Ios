//
//  SubscribeNotifyInstance.h
//  KBeacon
//
//  Created by hogen on 2020/11/15.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <KBCfgTrigger.h>
#import <KBNotifyDataBase.h>

NS_ASSUME_NONNULL_BEGIN

@class KBeacon;

@protocol KBNotifyDataDelegate<NSObject>
-(void)onNotifyDataReceived:(KBeacon*)beacon type:(int)dataType data:(KBNotifyDataBase*)data;
@end

@interface KBSubscribeNotifyItem : NSObject
    @property (strong) NSNumber* notifyType;

    @property (assign) Class notifyClass;

    @property(nonatomic,weak)id<KBNotifyDataDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
