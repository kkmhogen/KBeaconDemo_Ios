//
//  HtSensorTableViewCell.h
//  KBeacon
//
//  Created by hogen on 2020/11/5.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HtSensorTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mRecordUTCTime;

@property (weak, nonatomic) IBOutlet UILabel *mTemperature;

@property (weak, nonatomic) IBOutlet UILabel *mHumidity;

@end

NS_ASSUME_NONNULL_END
