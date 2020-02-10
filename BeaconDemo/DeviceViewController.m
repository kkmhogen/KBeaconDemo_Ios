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
#import "kbeaconlib/KBCfgTrigger.h"

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
    [self.mBtnConfigTest setEnabled:NO];
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
        [self.mBtnConfigTest setEnabled:YES];
    }
    else
    {
        [_actionConnect setTitle:BEACON_CONNECT];
        _actionConnect.tag = ACTION_CONNECT;
        [self.mDownCfgBtn setEnabled:NO];
        [self.mBtnConfigTest setEnabled:NO];
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
        
        //set beacon type to iBeacon
        pCommonCfg.advType = [NSNumber numberWithInt: KBAdvTypeIBeacon];
        
        //device name
        if (_txtName.tag == TXT_DATA_MODIFIED)
        {
            pCommonCfg.name = _txtName.text;
        }
        
        //tx power
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
        
        //set adv period
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
        
        //modify ibeacon uuid
        if (_txtBeaconUUID.tag == TXT_DATA_MODIFIED)
        {
            if (![KBUtility isUUIDString:_txtBeaconUUID.text])
            {
                [self showDialogMsg:@"error" message: @"UUID data length invalid"];
                return;
            }
                
            pIBeaconCfg.uuid = _txtBeaconUUID.text;
        }
        
        //modify ibeacon major id
        if (_txtBeaconMajor.tag == TXT_DATA_MODIFIED)
        {
            if ([_txtBeaconMajor.text intValue] > 65535)
            {
                [self showDialogMsg:@"error" message: @"major id data invalid"];
                return;
            }
            pIBeaconCfg.majorID = [NSNumber numberWithInt:[_txtBeaconMajor.text intValue]];
        }
        
        //modify ibeacon minor
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

- (IBAction)onConfigTest:(id)sender {
    //[self ringDevice];

    //test write button trigger
    [self enableButtonTrigger];
    
    //test read button trigger
    //[self readButtonTriggerPara];
}

//enable button trigger
-(void)enableButtonTrigger
{
    if (self.beacon.state != KBStateConnected){
        return;
    }
    
    //check if device can support button trigger capibility
    if (([self.beacon.triggerCapibility intValue] & KBTriggerTypeButton) == 0)
    {
        return;
    }
    
    KBCfgTrigger* btnTriggerPara = [[KBCfgTrigger alloc]init];
    
    //set trigger type
    btnTriggerPara.triggerType = [NSNumber numberWithInt: KBTriggerTypeButton];
    
    //set trigger advertisement enable
    btnTriggerPara.triggerAction = [NSNumber numberWithInt: KBTriggerActionAdv];

    //set trigger adv mode to adv only on trigger
    btnTriggerPara.triggerAdvMode = [NSNumber numberWithInt:KBTriggerAdvOnlyMode];
    
    //set trigger button para
    btnTriggerPara.triggerPara = [NSNumber numberWithInt: (KBTriggerBtnSingleClick | KBTriggerBtnDoubleClick)];
    
    //set trigger adv type
    btnTriggerPara.triggerAdvType = [NSNumber numberWithInt:KBAdvTypeIBeacon];
    
    //set trigger adv duration to 20 seconds
    btnTriggerPara.triggerAdvTime = [NSNumber numberWithInt: 20];

    //set the trigger adv interval to 500ms
    btnTriggerPara.triggerAdvInterval = [NSNumber numberWithInt: 500];
    
    [self.beacon modifyTriggerConfig:btnTriggerPara callback:^(BOOL bConfigSuccess, NSError * _Nonnull error) {
        if (bConfigSuccess)
        {
            NSLog(@"modify btn trigger success");
        }
        else
        {
            NSLog(@"modify btn trigger fail:%ld", (long)error.code);
        }
    }];
}

//disable button trigger
-(void)disableButtonTrigger
{
    if (self.beacon.state != KBStateConnected){
        return;
    }
    
    //check if device can support button trigger capibility
    if (([self.beacon.triggerCapibility intValue] & KBTriggerTypeButton) == 0)
    {
        return;
    }
    
    KBCfgTrigger* btnTriggerPara = [[KBCfgTrigger alloc]init];
    
    //set trigger type
    btnTriggerPara.triggerType = [NSNumber numberWithInt: KBTriggerTypeButton];
    
    //set trigger advertisement enable
    btnTriggerPara.triggerAction = [NSNumber numberWithInt: KBTriggerActionOff];
    
    [self.beacon modifyTriggerConfig:btnTriggerPara callback:^(BOOL bConfigSuccess, NSError * _Nonnull error) {
        if (bConfigSuccess)
        {
            NSLog(@"modify btn trigger success");
        }
        else
        {
            NSLog(@"modify btn trigger fail:%ld", (long)error.code);
        }
    }];
}

//read button trigger information
-(void)readButtonTriggerPara
{
    if (self.beacon.state != KBStateConnected){
        return;
    }
    
    //check if device can support button trigger capibility
    if (([self.beacon.triggerCapibility intValue] & KBTriggerTypeButton) == 0)
    {
        return;
    }
    
    [self.beacon readTriggerConfig:KBTriggerTypeButton callback:^(BOOL bConfigSuccess, NSDictionary * _Nullable readPara, NSError * _Nullable error) {
        if (bConfigSuccess)
        {
            NSArray* btnTriggerCfg = [readPara objectForKey:@"trObj"];
            if (btnTriggerCfg != nil)
            {
                KBCfgTrigger* btnCfg = [btnTriggerCfg objectAtIndex:0];
                NSLog(@"trigger type:%d", [btnCfg.triggerType intValue]);
                if ([btnCfg.triggerAction intValue] > 0)
                {
                    //button enable mask
                    int nButtonEnableInfo = [btnCfg.triggerPara intValue];
                    if ((nButtonEnableInfo & KBTriggerBtnSingleClick) > 0)
                    {
                        NSLog(@"Enable single click trigger");
                    }
                    if ((nButtonEnableInfo & KBTriggerBtnDoubleClick) > 0)
                    {
                        NSLog(@"Enable double click trigger");
                    }
                    if ((nButtonEnableInfo & KBTriggerBtnHold) > 0)
                    {
                        NSLog(@"Enable hold press trigger");
                    }
                    
                    //button trigger adv mode
                    if ([btnCfg.triggerAdvMode intValue] == KBTriggerAdvOnlyMode)
                    {
                        NSLog(@"device only advertisement when trigger event happened");
                    }
                    else if ([btnCfg.triggerAdvMode intValue] == KBTriggerAdv2AliveMode)
                    {
                        NSLog(@"device will always advertisement, but the uuid is difference when trigger event happened");
                    }
                                        
                    //button trigger adv type
                    NSLog(@"Button trigger adv type:%d", [btnCfg.triggerAdvType intValue]);
                    
                    //button trigger adv duration, uint is sec
                    NSLog(@"Button trigger adv duration:%dsec", [btnCfg.triggerAdvTime intValue]);

                    //button trigger adv interval, uint is ms
                    NSLog(@"Button trigger adv interval:%dms", [btnCfg.triggerAdvInterval intValue]);
                }
                else
                {
                    NSLog(@"Button trigger disable");
                }
            }
        }
        else
        {
            NSLog(@"Button trigger failed, %ld", (long)error.code);
        }
    }];
}

-(void) ringDevice
{
    if (self.beacon.state != KBStateConnected){
        return;
    }

    NSMutableDictionary* paraDicts = [[NSMutableDictionary alloc]init];

    [paraDicts setValue:@"ring" forKey:@"msg"];
    
    //ring times, uint is ms
    [paraDicts setValue:[NSNumber numberWithInt:20000] forKey:@"ringTime"];
    
    //0x0:led flash only; 0x1:beep alert only; 0x2 led flash and beep alert;
    [paraDicts setValue:[NSNumber numberWithInt:2] forKey:@"ringType"];
    
    //led flash on time. valid when ringType set to 0x0 or 0x2
    [paraDicts setValue:[NSNumber numberWithInt:200] forKey:@"ledOn"];

    //led flash off time. valid when ringType set to 0x0 or 0x2
    [paraDicts setValue:[NSNumber numberWithInt:1800] forKey:@"ledOff"];

    [self.beacon sendCommand:paraDicts callback:^(BOOL bConfigSuccess, NSError * _Nonnull error)
    {
        if (bConfigSuccess)
        {
            NSLog(@"send ring command to device success");
        }
        else
        {
            NSLog(@"send ring command to device failed");
        }
    }];
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
