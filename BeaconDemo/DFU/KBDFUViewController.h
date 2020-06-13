//
//  KBDFUViewController.h
//  KBeacon
//
//  Created by hogen on 2020/6/10.
//  Copyright © 2020 hogen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iOSDFULibrary-Swift.h>
#import <kbeaconlib/KBeacon.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBDFUViewController : UIViewController<ConnStateDelegate, UITextFieldDelegate, DFUServiceDelegate, DFUProgressDelegate>

@property (weak, nonatomic) KBeacon* beacon;

@property (weak, nonatomic) IBOutlet UILabel *mDFUStatusLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *mDFUProgresser;

@property (weak, nonatomic) IBOutlet UILabel *mReleaseVerLabel;

@property (weak, nonatomic) IBOutlet UILabel *mReleaseNotesLabel;


@end

NS_ASSUME_NONNULL_END
