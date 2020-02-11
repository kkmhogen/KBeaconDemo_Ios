#KBeacon IOS SDK Instruction DOC（English）

----
## 1. Introduction
We provide AAR format SDK library on Github, you can found it in directory:   
./kbeaconlib.framework

With this SDK, you can scan and configure the KBeacon device. The SDK include follow main class:
* KBeaconsMgr: Global definition, responsible for scanning KBeacon devices advertisment packet, and monitoring the Bluetooth status of the system;

* KBeacon: An instance of a KBeacon device, KBeaconsMgr creates an instance of KBeacon while it found a physical device. Each KBeacon instance has three properties: KBAdvPacketHandler, KBAuthHandler, KBCfgHandler.

* KBAdvPacketHandler: parsing advertisement packet. This attribute is valid during the scan phase.

*	KBAuthHandler: responsible for the authentication operation with the KBeacon device after the connection is established.

*	KBCfgHandler：responsible for configuring parameters related to KBeacon devices
![avatar](https://github.com/kkmhogen/KBeaconDemo_Android/blob/master/kbeacon_class_arc.png?raw=true)

**Scanning Stage**

in this stage, KBeaconsMgr will scan and parse the advertisement packet about KBeacon devices, and it will create "KBeacon" instance for every founded devices, developers can get all advertisements data by its allAdvPackets or getAdvPacketByType function.

**Connection Stage**

After a KBeacon connected, developer can make some changes of the device by modifyConfig.


## 2. IOS demo
To make your development easier, we have an IOS demos in github. They are:  
* KBeaconDemo_Ios: The app can scan KBeacon devices and configure iBeacon related parameters.


## 3. Import SDK to project
### 3.1 Prepare
Development environment:  
min IOS Version 10.0

### 3.2 Import SDK
1. Add the kbeaconlib.framework into your project. As shown below:  
![avatar](https://github.com/kkmhogen/KBeaconDemo_Ios/blob/master/addlibrary.png?raw=true)

2. Add the Bluetooth permissions declare in your project plist file(Target->Info). As follows:  
* Privacy - Bluetooth Always Usage Description
* Privacy - Bluetooth Peripheral Usage Description


## 4. How to use SDK
### 4.1 Scanning device
1. Init KBeaconMgr instance in Activity, also your application should implementation the KBeaconMgr's KBeaconMgrDelegate.

```objective-c
- (void)viewDidLoad {
	//other code...
  //init kbeacon manager
  mBeaconsMgr = [KBeaconsMgr sharedBeaconManager];
  mBeaconsMgr.delegate = self;
	//other code...  
}  
```

2. implementation KBeaconMgrDelegate   

```objective-c
-(void)onBeaconDiscovered:(NSArray<KBeacon*>*)beacons
{
  //found device
}
-(void)onCentralBleStateChange:(BLECentralMgrState)newState
{
    if (newState == BLEStatePowerOn)
    {
        //the app can start scan in this case
        NSLog(@"central ble state power on");
    }
}
```

3. Start scanning  
After app startup, the BLE state is set to unknown, so the app should wait serval millseconds before start scanning.

```objective-c
  int nStartScan = [mBeaconsMgr startScanning];
  if (nStartScan == 0)
  {
      NSLog(@"start scan success");
      self.actionButton.title = ACTION_STOP_SCAN;
  }
  else if (nStartScan == SCAN_ERROR_BLE_NOT_ENABLE) {
      [self showMsgDlog:@"error" message:@"BLE function is not enable"];

  }
  else if (nStartScan == SCAN_ERROR_NO_PERMISSION) {
      [self showMsgDlog:@"error" message:@"BLE scanning has no location permission"];
  }
  else
  {
      [self showMsgDlog:@"error" message:@"BLE scanning unknown error"];
  }
```

4. implementation KBeaconMgr delegate to get scanning result

```objective-c
-(void)onBeaconDiscovered:(NSArray<KBeacon*>*)beacons
{
    KBeacon* pBeacon = nil;
    for (int i = 0; i < beacons.count; i++)
    {
        pBeacon = [beacons objectAtIndex:i];

        //get common data
        //device can be connectable ?
        cell.connectableLabel.text = [NSString stringWithFormat:@"Conn:%@", pBeacons.isConnectable ? @"yes":@"no"];

        //mac
        if (pBeacons.mac != nil)
        {
            cell.macLabel.text = [NSString stringWithFormat:@"mac:%@", pBeacons.mac];
        }

        //battery percent
        if (pBeacons.batteryPercent != nil)
        {
           cell.voltageLabel.text = [NSString stringWithFormat:@"Batt:%@", [pBeacons.batteryPercent stringValue]];
        }

        //device name
        if (pBeacons.name != nil){
            cell.deviceNameLabel.text = pBeacons.name;
        }else{
            cell.deviceNameLabel.text = @"N/A";
        }

        //rssi
        if (pBeacons.rssi != nil)
        {
            cell.rssiLabel.text = [NSString stringWithFormat:@"rssi:%@", [pBeacons.rssi stringValue]];
        }

        //filter iBeacon packet
        KBAdvPacketIBeacon* piBeaconAdvPacket = (KBAdvPacketIBeacon*)[pBeacons getAdvPacketByType:KBAdvTypeIBeacon];
        if (piBeaconAdvPacket != nil)
        {
            //because IOS app can not get UUID from advertisement, so we try to get uuid from configruation database, the UUID will only avaiable when device ever conneced
            KBCfgIBeacon* pIBeaconCfg = (KBCfgIBeacon*)[pBeacons getConfigruationByType:KBConfigTypeIBeacon];
            if (pIBeaconCfg != nil)
            {
                cell.uuidLabel.text = [NSString stringWithFormat:@"major:%@",
                                       pIBeaconCfg.uuid];
            }

            //get majorID from advertisement packet
            //notify: this is not standard iBeacon protocol, we get major ID from KKM private
            //scan response message
            if (piBeaconAdvPacket.majorID != nil)
            {
                cell.majorLabel.text = [NSString stringWithFormat:@"major:%@",[piBeaconAdvPacket.majorID stringValue]];
            }

            //get majorID from advertisement packet
            //notify: this is not standard iBeacon protocol, we get minor ID from KKM private
            //scan response message
            if (piBeaconAdvPacket.minorID != nil)
            {
                cell.minorLabel.text = [NSString stringWithFormat:@"minor:%@",[piBeaconAdvPacket.minorID stringValue]];
            }
        }
    }

    mBeaconsArray = [mBeaconsDictory allValues];
    [_beaconsTableView reloadData];
}
```

4. Clean scanning result and stop scanning  
After start scanning, The KBeaconMgr will buffer all found KBeacon device. If the app want to remove all buffered KBeacon device, the app can:  

```objective-c
[mBeaconsMgr clearBeacons];
```

If the app want to stop scanning:
```objective-c
[mBeaconsMgr stopScanning];
```

### 4.2 Connect to device
 1. If the app want to change the device parameters, then it need connect to the device.
 ```objective-c
 self.beacon.delegate = self;
[self.beacon connect:password timeout:20];
 ```
* Password: device password, the default password is 0000000000000000
* timeout: max connection timer, uint is ms.

2. the app should implementation the KBeacon's delegate for get connection status:
 ```objective-c
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
 ```

3. disconnec from the device.
 ```objective-c
[self.beacon disconnect];
 ```

### 4.3 Configure parameters
#### 4.3.1 Advertisment type
KBeacon devices support sending multiple beacon advertisment packet in parallel.  
For example, advertisment period was set to 500ms. Advertisment type was set to “iBeacon + URL + UID + KSensor”, then the device will send advertisment packet like follow.   

|Time(ms)|0|500|1000|1500|2000|2500|3000|3500
|----|----|----|----|----|----|----|----|----
|`Adv type`|KSensor|UID|iBeacon|URL|KSensor|UID|iBeacon|URL


If the advertisment type include TLM, the TLM advertisment interval is fixed to 10. It means the TLM will advertisement every 10 other advertisement packet.  
For example: advertisment period was set to 500ms. Advertisment type was set to “URL + TLM”, then the advertisment packet is like follow

|Time|0|500|1000|1500|2000|2500|3000|3500|4000|4500|5000
|----|----|----|----|----|----|----|----|----|----|----|----
|`Adv type`|URL|URL|URL|URL|URL|URL|URL|URL|URL|TLM|URL


#### 4.3.2 Get device parameters
After the app connect to KBeacon success. The KBeacon will automatically read current parameters from physical device. so the app can update UI and show the parameters to user after connection setup.  
 ```objective-c
 -(void)onConnStateChange:(KBeacon*)beacon state:(KBConnState)state evt:(KBConnEvtReason)evt;
 {
     if (state == KBStateConnected)
     {
         [self updateDeviceToView];
     }
 }

//update device's configuration  to UI
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
 ```

#### 4.3.3 Update device parameters

After app connect to device success, the app can update update parameters of physical device.
Example1: app update tx power, device name  

```objective-c
-(void)simpleUpdateDeviceTest
{
    if (_beacon.state != KBStateConnected)
    {
        NSLog(@"beacon not connected");
        return;
    }

    KBCfgCommon* pCommonCfg = [[KBCfgCommon alloc]init];

    @try {
        pCommonCfg.name = @"KBeacon";
        pCommonCfg.txPower = [NSNumber numberWithInt:-4];
    }
    @catch (KBException *exception)
    {
        return;
    }

    NSArray* configParas = @[pCommonCfg];
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
```

Sometimes the app need to configure multiple parameters at the same time. We recommend that the app should check whether the parameters was changed before update. If the parameters value is no change, the app do not need to send the configuration.  
Example2: check if the parameters was changed, then send new parameters to device
```objective-c
//read user input and download to KBeacon device
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
        NSString* errorInfo = [NSString stringWithFormat:@"input parameters invalid:%ld",
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
```

#### 4.3.4 Modify trigger parameters
 For some KBeacon device that has motion or push button. The app can set advertisement trigger and the device will advertise when the trigger condition is met. the trigger advertisement has follow parameters:
 * Trigger advertisement Mode: There are two modes of trigger advertisement. One mode is to broadcast only when the trigger is satisfied. The other mode is always broadcasting, and the content of advertisement packet will change when the trigger conditions are met.

 *	Trigger parameters: For motion trigger, the parameters is accleration sensitivity. For button trigger, you can set different trigger event(single click, double click, etc.,).

 *	Trigger advertisement type: The advertisement packet type when trigger event happened. it can be seting to iBeacon, Eddystone or KSensor advertisement.

 *	Trigger advertisement duration: The advertisement duration when trigger event happened.

 *	Trigger advertisement interval: The bluetooth advertisement interval for trigger advertisement.  You can set a different value from alive broadcast.

 Example 1:  
  &nbsp;&nbsp;Trigger adv mode: seting to broadcast only on trigger event happened  
  &nbsp;&nbsp;Trigger adv type: iBeacon  
  &nbsp;&nbsp;Trigger adv duration: 30 seconds  
	&nbsp;&nbsp;Trigger adv interval: 300ms  
	![avatar](https://github.com/kkmhogen/KBeaconDemo_Android/blob/master/only_adv_when_trigger.png?raw=true)

 Example 2:  
	&nbsp;For some senario, we need to continuously monitor the KBeacon to ensure that the device was alive, so we set the trigger advertisement mode to always advertisement.   
	&nbsp;We set an larger advertisement interval during alive advertisement and a short advertisement interval when trigger event happened, so we can achieve a balance between power consumption and triggers advertisement be easily detected.  
   &nbsp;&nbsp;Trigger adv mode: seting to Always advertisment  
   &nbsp;&nbsp;Trigger adv type: iBeacon  
   &nbsp;&nbsp;Trigger adv duration: 30 seconds  
 	 &nbsp;&nbsp;Trigger adv interval: 300ms  
	 &nbsp;&nbsp;Always adv interval: 2000ms
 	![avatar](https://github.com/kkmhogen/KBeaconDemo_Android/blob/master/always_adv_with_trigger.png?raw=true)

**Notify:**  
	  The SDK will not automatically read trigger configuration after connection setup complete. So the app need read the trigger configuration manual if the app needed. Please referance 4.3.4.1 code for read trigger parameters from device.  

#### 4.3.4.1 Push button trigger
The push button trigger feature is used in some hospitals, nursing homes and other scenarios. When the user encounters some emergency event, they can click the button and the KBeacon device will start broadcast.
The app can configure single click, double-click, triple-click, long-press the button trigger, oor a combination.

**Notify:**  
* By KBeacon's default setting, long press button used to power on and off. Clicking button used to force the KBeacon enter connectable broadcast advertisement. So when you enable the long-press button trigger, the long-press power off function will be disabled. When you turn on the single/dobule/triple click trigger, the function of clicking to enter connectable broadcast state will also be disabled. After you disable button trigger, the default function about long press or click button will take effect again.
* iBeacon UUID for single click trigger = Always iBeacon UUID + 0x5
* iBeacon UUID for single double trigger = Always iBeacon UUID + 0x6
* iBeacon UUID for single triple trigger = Always iBeacon UUID + 0x7
* iBeacon UUID for single long press trigger = Always iBeacon UUID + 0x8

1. Enable or button trigger feature.

```objective-c
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
```

2. The app can disable the button trigger

```objective-c
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
```

3. The app can read the button current trigger parameters from KBeacon by follow code  

```objective-c
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

    [self.beacon readTriggerConfig:KBTriggerTypeButton callback:^(BOOL bConfigSuccess, NSDictionary * _Nullable readPara, NSError * _Nullable error)
		{
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

 ```

#### 4.3.4.2 Motion trigger
Motion Trigger means that when the device detects movement, it will start broadcasting. You can set the sensitivity of motion detection.  

**Notify:**  
* When the KBeacon enable the motion trigger, the Acc feature(X, Y, and Z axis detected function) in the KSensor broadcast will be disabled.
* iBeacon UUID for motion trigger = Always iBeacon UUID + 0x1

Enabling motion trigger is similar to push button trigger, which will not be described in detail here.
1. Enable or button trigger feature.  

```objective-c
-(void)enableMotionTrigger
{
    ... same as push button trigger

    //check if device can support motion trigger capibility
    if (([self.beacon.triggerCapibility intValue] & KBTriggerTypeMotion) == 0)
    {
        return;
    }

    ... same as push button trigger

    //set trigger type
    btnTriggerPara.triggerType = [NSNumber numberWithInt: KBTriggerTypeMotion];

    //set motion trigger sensitivity, the valid range is 2~31. The uint is 16mg.
    btnTriggerPara.triggerPara = [NSNumber numberWithInt: 3];

    ... same as push button trigger
}
```

#### 4.3.5 Send command to device
After app connect to device success, the app can send command to device.  
All command message between app and KBeacon are JSON format. our SDK provide HashMap to encapsulate these JSON message.

#### 4.3.5.1 Ring device
 For some KBeacon device that has buzzer function. The app can ring device. for ring command, it has 5 parameters:
 * msg: msg type is 'ring'
 * ringTime: uint is ms. The KBeacon will start flash/alert for 'ringTime' millisecond  when receive this command.
 * ringType: 0x0:led flash only; 0x1:beep alert only; 0x2 both led flash and beep;
 * ledOn: optional parameters, uint is ms.the LED will flash at interval (ledOn + ledOff).  This parameters is valid when ringType set to 0x0 or 0x2.
 * ledOff: optional parameters, uint is ms. the LED will flash at interval (ledOn + ledOff).  This parameters is valid when ringType set to 0x0 or 0x2.

```objective-c
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
```
#### 4.3.5.2 Reset configruation to default
 The app can using follow command to reset all configruation to default.
 * msg: msg type is 'reset'

```objective-c
//set parameter to default
-(void)resetParametersToDefault
{
    if (self.beacon.state != KBStateConnected){
        return;
    }

    NSMutableDictionary* paraDicts = [[NSMutableDictionary alloc]init];
    [paraDicts setValue:@"reset" forKey:@"msg"];
    [self.beacon sendCommand:paraDicts callback:^(BOOL bConfigSuccess, NSError * _Nonnull error)
    {
        if (bConfigSuccess)
        {
            //disconnect with device to make sure the paramaters to take effect
            [self.beacon disconnect];
            NSLog(@"send reset command to device success");
        }
        else
        {
            NSLog(@"send reset command to device failed");
        }
    }];
}
```
#### 4.3.6 Error cause in configruation/command
 The app can using follow command to reset all configruation to default.
 * KBException.KBEvtCfgNoParamaters: parameters is null
 * KBEvtCfgBusy : device is busy, please make sure last configruation complete
 * KBEvtCfgFailed: device return failed.
 * KBEvtCfgTimeout: configruation timeout
 * KBEvtCfgInputInvalid: input paramaters data not in valid range
 * KBEvtCfgStateError: device is not in connected state
 * KBEvtCfgNotSupport: device does not support the parameters

 ```objective-c
{
    ...another code
    
    //start configruation
    [_beacon modifyConfig:configParas callback:^(BOOL bCfgRslt, NSError* error)
    {
       if (bCfgRslt)
       {
           [self showDialogMsg: @"Success" message: @"config beacon success"];
       }
       else if (error != nil)
       {
           if (error.code == KBEvtCfgBusy)
           {
               NSLog(@"Config busy, please make sure other configruation complete");
           }
           else if (error.code == KBEvtCfgTimeout)
           {
               NSLog(@"Config timeout");
           }
           ...other code
       }
    }];
}
 ```

## 5. Change log
* 2020.1.11 v1.2 add trigger function
* 2019.10.11 v1.1 add KSesnor function
* 2019.4.1 v1.0 first version;
