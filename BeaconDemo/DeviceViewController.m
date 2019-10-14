//
//  DeviceViewController.m
//  KBeaconDemo
//
//  Created by kkm on 2018/12/9.
//  Copyright © 2018 kkm. All rights reserved.
//

#import "DeviceViewController.h"
#import "kbeaconlib/KBeacon.h"
#import "string.h"
#import "KBPreferance.h"
#import "kbeaconlib/KBCfgIBeacon.h"

#define ACTION_CONNECT 0x0
#define ACTION_DISCONNECT 0x1
#define TXT_DATA_MODIFIED 0x1

@interface DeviceViewController ()

@end

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.actionConnect setTitle: BEACON_CONNECT];
    [self.actionConnect setTag:ACTION_CONNECT];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
    [self.view addGestureRecognizer:tap];
    
    [self.mDownCfgBtn setEnabled:NO];
    self.txtName.delegate = self;
    self.txtTxPower.delegate = self;
    self.txtAdvPeriod.delegate = self;
    self.txtBeaconUUID.delegate = self;
    self.txtBeaconMajor.delegate = self;
    self.txtBeaconMinor.delegate = self;
}

-(void)tap
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

-(void)updateActionButton
{
    if (_beacon.state == KBStateConnected)
    {
        [_actionConnect setTitle:BEACON_DISCONNECT];
        _actionConnect.tag = ACTION_DISCONNECT;
        [self.mDownCfgBtn setEnabled:YES];
    }
    else
    {
        [_actionConnect setTitle:BEACON_CONNECT];
        _actionConnect.tag = ACTION_CONNECT;
        [self.mDownCfgBtn setEnabled:NO];
    }
}

-(void)onConnStateChange:(KBeacon*)beacon state:(KBConnState)state evt:(KBConnEvtReason)evt;
{
    if (state == KBStateConnecting)
    {
        self.txtBeaconStatus.text = @"Connecting to device";
    }
    else if (state == KBStateConnected)
    {
        self.txtBeaconStatus.text = @"Device connected";
        
        [self updateDeviceToView];
    }
    else if (state == KBStateDisconnected)
    {
        self.txtBeaconStatus.text = @"Device disconnected";
        if (evt == KBEvtConnAuthFail)
        {
            NSLog(@"auth failed");
            [self showPasswordInputDlg];
        }
    }
    
    [self updateActionButton];
}

-(void) showPasswordInputDlg
{
    UIAlertController *alertDlg = [UIAlertController alertControllerWithTitle:@"Auth fail" message:@"Please input beacon password" preferredStyle:UIAlertControllerStyleAlert];
    [alertDlg addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"password: 8~16 characteristics";
    }];
    [alertDlg addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertDlg addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        NSArray * arr = alertDlg.textFields;
        UITextField * field = arr[0];
        
        KBPreferance* pref = [KBPreferance sharedManager];
        [pref saveBeaconPassword:self.beacon.UUIDString pwd:field.text];
        
        [self.beacon connect:field.text timeout:20];
     }]];
    
    [self presentViewController:alertDlg animated:YES completion:nil];
}

-(void)updateDeviceToView
{
    KBCfgCommon* pCommonCfg = (KBCfgCommon*)[self.beacon getConfigruationByType:KBConfigTypeCommon];
    if (pCommonCfg != nil)
    {
        NSLog(@"support iBeacon:%@", [pCommonCfg isSupportIBeacon]?@"1":@"0");
        NSLog(@"support eddy url:%@", [pCommonCfg isSupportEddyURL]?@"1":@"0");
        NSLog(@"support eddy tlm:%@", [pCommonCfg isSupportEddyTLM]?@"1":@"0");
        NSLog(@"support eddy uid:%@", [pCommonCfg isSupportEddyUID]?@"1":@"0");
        NSLog(@"support ksensor:%@", [pCommonCfg isSupportKBSensor]?@"1":@"0");
        NSLog(@"support has button:%@", [pCommonCfg isSupportButton]?@"1":@"0");
        NSLog(@"support beep:%@", [pCommonCfg isSupportBeep]?@"1":@"0");
        NSLog(@"support accleration:%@", [pCommonCfg isSupportAccSensor]?@"1":@"0");
        NSLog(@"support humidify:%@", [pCommonCfg isSupportHumiditySensor]?@"1":@"0");
        NSLog(@"support max tx power:%d", [pCommonCfg.maxTxPower intValue]);
        NSLog(@"support min tx power:%d", [pCommonCfg.minTxPower intValue]);
        
        self.labelBeaconType.text = pCommonCfg.advTypeString;
        self.txtName.text = pCommonCfg.name;
        self.labelModel.text = pCommonCfg.model;
        self.labelVersion.text = pCommonCfg.version;
        self.txtTxPower.text = [pCommonCfg.txPower stringValue];
        self.txtAdvPeriod.text = [pCommonCfg.advPeriod stringValue];
        
        KBCfgIBeacon* pIBeacon = (KBCfgIBeacon*)[self.beacon getConfigruationByType:KBConfigTypeIBeacon];
        if (pIBeacon != nil)
        {
            self.txtBeaconUUID.text = pIBeacon.uuid;
            self.txtBeaconMajor.text = [pIBeacon.majorID stringValue];
            self.txtBeaconMinor.text = [pIBeacon.minorID stringValue];
        }
    }
}

- (IBAction)onActionItemClick:(id)sender {
    
    if (_actionConnect.tag == ACTION_CONNECT)
    {
        _beacon.delegate = self;
        KBPreferance* pref = [KBPreferance sharedManager];
        NSString* beaconPwd = [pref getBeaconPassword: _beacon.UUIDString];
        [_beacon connect:beaconPwd timeout:20];
        
        [_actionConnect setTitle:BEACON_DISCONNECT];
        _actionConnect.tag = ACTION_DISCONNECT;
    }
    else
    {
        [_beacon disconnect];
        
        [_actionConnect setTitle:BEACON_CONNECT];
        _actionConnect.tag = ACTION_CONNECT;
    }
}

-(void)updateViewToDevice
{
    if (_beacon.state != KBStateConnected)
    {
        NSLog(@"beacon not connected");
        return;
    }
    
    KBCfgIBeacon* pIBeaconCfg = [[KBCfgIBeacon alloc]init];
    KBCfgCommon* pCommonCfg = [[KBCfgCommon alloc]init];
    
    @try {
        if (_txtName.tag == TXT_DATA_MODIFIED)
        {
            pCommonCfg.name = _txtName.text;
        }
        if (_txtTxPower.tag == TXT_DATA_MODIFIED)
        {
            int nTxPower = [_txtTxPower.text intValue];
            
            if (nTxPower > [_beacon.maxTxPower intValue]
                || nTxPower < [_beacon.minTxPower intValue])
            {
                [self showDialogMsg:@"error" message: @"Tx power is invalid"];
                return;
            }
            
            pCommonCfg.txPower = [NSNumber numberWithInt:nTxPower];
        }
        if (_txtAdvPeriod.tag == TXT_DATA_MODIFIED)
        {
            if ([_txtAdvPeriod.text intValue] < 100
                || [_txtAdvPeriod.text intValue] > 10000)
            {
                [self showDialogMsg:@"error" message: @"adv period is invalid"];
                return;
            }
            
            pCommonCfg.advPeriod = [NSNumber numberWithInt:[_txtAdvPeriod.text intValue]];
        }
        
        if (_txtBeaconUUID.tag == TXT_DATA_MODIFIED)
        {
            if (![KBUtility isUUIDString:_txtBeaconUUID.text])
            {
                [self showDialogMsg:@"error" message: @"UUID data length invalid"];
                return;
            }
                
            pIBeaconCfg.uuid = _txtBeaconUUID.text;
        }
        if (_txtBeaconMajor.tag == TXT_DATA_MODIFIED)
        {
            if ([_txtBeaconMajor.text intValue] > 65535)
            {
                [self showDialogMsg:@"error" message: @"major id data invalid"];
                return;
            }
            pIBeaconCfg.majorID = [NSNumber numberWithInt:[_txtBeaconMajor.text intValue]];
        }
        if (_txtBeaconMinor.tag == TXT_DATA_MODIFIED)
        {
            if ([_txtBeaconMinor.text intValue] > 65535)
            {
                [self showDialogMsg:@"error" message: @"minor id data invalid"];
                return;
            }
            pIBeaconCfg.minorID = [NSNumber numberWithInt:[_txtBeaconMinor.text intValue]];
        }
    }
    @catch (KBException *exception)
    {
        NSString* errorInfo = [NSString stringWithFormat:@"input paramaters invalid:%ld",
                               (long)exception.errorCode];
        [self showDialogMsg: @"error" message: errorInfo];
        return;
    }
    
    
    NSArray* configParas = @[pCommonCfg, pIBeaconCfg];
    
    //start configruation
    [_beacon modifyConfig:configParas callback:^(BOOL bCfgRslt, NSError* error)
     {
         if (bCfgRslt)
         {
             [self showDialogMsg: @"Success" message: @"config beacon success"];
         }
         else if (error != nil)
         {
             [self showDialogMsg:@"Failed" message:[NSString stringWithFormat:@"config error:%@",error.localizedDescription]];
         }
     }];
}

- (IBAction)onStartConfig:(id)sender {
    
    [self updateViewToDevice];
}

-(void)showDialogMsg:(NSString*)title message:(NSString*)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OkAction = [UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:OkAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.beacon disconnect];
}

- (IBAction)onClickDownloadButton:(id)sender {
    
    if (_beacon.state != KBStateConnected)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ERR_TITLE message:ERR_BLE_FUNC_OFF preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OkAction = [UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDestructive handler:nil];
        [alertController addAction:OkAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //tag means data was change
    textField.tag = TXT_DATA_MODIFIED;
    
    return YES;
}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
