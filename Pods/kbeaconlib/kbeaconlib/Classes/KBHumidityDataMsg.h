//
//  KBHumidityDataMsg.h
//  KBeacon
//
//  Created by hogen on 2020/11/3.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <KBSensorDataMsgBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReadHTSensorInfoRsp : NSObject
@property (strong) NSNumber* totalRecordNumber;
@property (strong) NSNumber* unreadRecordNumber;
@property (strong) NSNumber* readInfoUtcSeconds;
@end

@interface ReadHTSensorDataRsp : NSObject
@property (strong) NSNumber* readDataNextPos;
@property (strong) NSMutableArray* readDataRspList;
@end

@interface KBHumidityDataMsg : KBSensorDataMsgBase



@end

NS_ASSUME_NONNULL_END
