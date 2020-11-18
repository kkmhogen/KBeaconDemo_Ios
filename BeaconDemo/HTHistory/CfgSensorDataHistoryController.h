//
//  CfgSensorDataHistoryController.h
//  KBeacon
//
//  Created by hogen on 2020/11/5.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KBeacon.h>

NS_ASSUME_NONNULL_BEGIN

@interface CfgSensorDataHistoryController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (weak, nonatomic) KBeacon* beacon;



@end

NS_ASSUME_NONNULL_END
