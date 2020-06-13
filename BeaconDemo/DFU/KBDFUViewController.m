//
//  KBDFUViewController.m
//  KBeacon
//
//  Created by hogen on 2020/6/10.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBDFUViewController.h"
#import "KBFirmwareDownload.h"
#import "string.h"

@interface KBDFUViewController ()
{
    KBFirmwareDownload* firmwareDownload;
    DFUServiceController *controller;
    NSString* latestFirmwareFileName;
    BOOL mInDfuState;
    BOOL mFoudNewVersion;
    
    id<ConnStateDelegate> mPrivousDelegation;
}
@end

@implementation KBDFUViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self->mInDfuState = NO;
    self->mFoudNewVersion = NO;
    self->firmwareDownload = [[KBFirmwareDownload alloc]init];
    
    [self.mDFUStatusLabel setText:DEVICE_CHECK_UPDATE];

    [self downloadFirmwareInfo];
}


-(void)onConnStateChange:(KBeacon*)beacon state:(KBConnState)state evt:(KBConnEvtReason)evt;
{
    if (state == KBStateDisconnected)
    {
        //start dfu
        if (self->mInDfuState)
        {
            [self updateFirmware];
        }
    }
}

-(void)dfuComplete:(NSString*)strDescription
{
    self->mInDfuState = NO;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:DFU_TITLE message:strDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        NSArray *controllers = self.navigationController.viewControllers;
        
        if (self.beacon.state == KBStateConnected)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self.navigationController popToViewController:[controllers objectAtIndex:0] animated:YES];
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dfuStateDidChangeTo:(enum DFUState)state
{
    switch (state) {
        case DFUStateConnecting:
            NSLog(@"DFU connecting");
            [self.mDFUStatusLabel setText:UPDATE_CONNECTING];
            break;
            
        case DFUStateEnablingDfuMode:
            NSLog(@"DFU mode");
            break;
            
        case DFUStateUploading:
            NSLog(@"DFU uploading");
            [self.mDFUStatusLabel setText:UPDATE_UPLOADING];
            break;
            
        case DFUStateDisconnecting:
            NSLog(@"DFU disconnecting");
            break;
            
        case DFUStateCompleted:
            NSLog(@"DFU complete");
            [self.mDFUStatusLabel setText:UPDATE_COMPLETE];
            self->mInDfuState = NO;
            [self dfuComplete: UPDATE_COMPLETE];
            break;
           
        case DFUStateAborted:
            NSLog(@"DFU complete");
            [self.mDFUStatusLabel setText:UPDATE_ABORTED];
            self->mInDfuState = NO;
            [self dfuComplete: UPDATE_ABORTED];
            break;
            
        default:
            break;
    }
}

-(void) showDialogMsg:(NSString*)title message:(NSString*)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
           UIAlertAction *OkAction = [UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:OkAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dfuError:(enum DFUError)error didOccurWithMessage:(NSString * _Nonnull)message
{
    
    [self showDialogMsg:DFU_TITLE message:message];
    
    [self.mDFUStatusLabel setText:UPDATE_ABORTED];
    
    self->mInDfuState = NO;
    
    [self dfuComplete: UPDATE_ABORTED];
}

- (void)dfuProgressDidChangeFor:(NSInteger)part outOf:(NSInteger)totalParts to:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond
{
    self.mDFUProgresser.progress = ((double)progress / 100);
    NSLog(@"DFU progress:%ld", (long)progress);
}

-(void)updateFirmware
{
    [self->firmwareDownload downLoadFirmwreData:self->latestFirmwareFileName callback:^(BOOL bResult, NSURL * _Nullable url, NSError * _Nullable error) {
        
         dispatch_async(dispatch_get_main_queue(), ^{
            if (bResult )
            {
                self->mInDfuState = YES;

                DFUFirmware *selectedFirmware = [[DFUFirmware alloc] initWithUrlToZipFile:url];

                dispatch_queue_t queue = dispatch_get_main_queue();
                DFUServiceInitiator *initiator = [[DFUServiceInitiator alloc] initWithQueue:queue delegateQueue:queue progressQueue:queue loggerQueue:queue];
                [initiator withFirmware:selectedFirmware];
                initiator.delegate = self; // -to be informed about current state and errors
                initiator.progressDelegate = self; // - to show progress bar
                
                self->controller = [initiator startWithTarget: self.beacon.peripheral];
             }
             else
             {
                 [self.mDFUStatusLabel setText:UPDATE_NETWORK_FAIL];
                 
                 [self dfuComplete:error.localizedDescription];
             }
         });
    }];
}
- (IBAction)onUpdateClick:(id)sender {
    if (self->mInDfuState)
    {
        NSLog(@"device is already in DFU state");
        return;
    }
    
    if (self->mFoudNewVersion)
    {
        [self makesureUpdateSelection];
    }
    else
    {
        [self showDialogMsg:DFU_TITLE message:UPDATE_NOT_FOUND_NEW_VERSION];
    }
}


-(void)makesureUpdateSelection
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:DFU_TITLE message:DFU_VERSION_MAKE_SURE preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OkAction = [UIAlertAction actionWithTitle:DLG_CANCEL style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:OkAction];

    [alertController addAction:[UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        self.mDFUProgresser.progress = 0;
        self->mInDfuState = YES;
        
        //update
        self->mPrivousDelegation = self.beacon.delegate;
        self.beacon.delegate = self;
        
        //disconnect for update
        if (self.beacon.state == KBStateConnected)
        {
            [self.beacon disconnect];
        }
        else
        {
            [self updateFirmware];
        }
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)downloadFirmwareInfo
{
    KBCfgCommon* cfgCommon = (KBCfgCommon*)[self.beacon getConfigruationByType:KBConfigTypeCommon];
    if (cfgCommon.hversion == nil || cfgCommon.version == nil)
    {
        NSLog(@"device does not have hardware version");
        return;
    }
    
    [firmwareDownload downloadFirmwareInfo:cfgCommon.model callback:^(BOOL bResult, NSDictionary * _Nullable info, NSError * _Nullable error)
    {
        if (bResult)
        {
            if (info == nil)
            {
                [self dfuComplete: DFU_CLOUDS_SERVER_ERROR];
                return;
            }
            
            NSArray* firmwareVerList = [info objectForKey:cfgCommon.hversion];
            if (firmwareVerList == nil)
            {
                [self dfuComplete: DFU_CLOUDS_FILE_NOT_EXIST];
                return;
            }
            
            NSString* currVerDigital = [cfgCommon.version substringFromIndex:1];
            NSMutableString *versionNotes = [[NSMutableString alloc]init];
            for(NSDictionary* obj in firmwareVerList)
            {
                NSString* remoteVersion = [obj objectForKey:@"appVersion"];
                if (remoteVersion == nil)
                {
                    [self dfuComplete: DFU_CLOUDS_SERVER_ERROR];
                    return;
                }
                
                NSString* remoteVerDigital = [remoteVersion substringFromIndex:1];
                if ([currVerDigital floatValue] < [remoteVerDigital floatValue])
                {
                    NSLog(@"Found new firmware version:%@.", remoteVerDigital);
                    
                    NSString* appFileName = [obj objectForKey:@"appFileName"];
                    if (appFileName == nil)
                    {
                        [self dfuComplete: DFU_CLOUDS_SERVER_ERROR];
                        return;
                    }
                    NSString* releaseNotes = [obj objectForKey:@"note"];
                    if (releaseNotes != nil)
                    {
                        [versionNotes appendString:releaseNotes];
                        [versionNotes appendString:@"\n"];
                    }

                    //check if it is the last
                    if (obj == [firmwareVerList lastObject])
                    {
                        self->latestFirmwareFileName = appFileName;
                        [self.mReleaseVerLabel setText:remoteVersion];
                        [self.mReleaseNotesLabel setText:versionNotes];
                        self->mFoudNewVersion = YES;
                        
                        NSString* strNewVersion = [NSString stringWithFormat:DFU_FOUND_NEW_VERSION, remoteVersion];
                        [self.mDFUStatusLabel setText:strNewVersion];
                        return;
                    }
                }
            }
            
            [self dfuComplete: DEVICE_LATEST_VERSION];
        }
        else
        {
            [self.mDFUStatusLabel setText:UPDATE_NETWORK_FAIL];
            NSString* errorDesc = [NSString stringWithFormat:@"%@ %@", UPDATE_NETWORK_FAIL, error.localizedDescription];
            [self dfuComplete: errorDesc];
        }
    }];
}

@end
