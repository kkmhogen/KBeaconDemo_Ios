//
//  KBProximityDataMsg.h
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KBSensorDataMsgBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBProximityInfoRsp : NSObject
@property (strong) NSNumber* readInfoRecordNumber;
@property (strong) NSNumber* readInfoUtcSeconds;
@end

@interface KBProximityDataRsp : NSObject
@property (strong) NSMutableArray* readDataList;
@property (strong) NSNumber* readDataNextNum;
@end

@interface KBProximityDataMsg : KBSensorDataMsgBase

@end

NS_ASSUME_NONNULL_END
