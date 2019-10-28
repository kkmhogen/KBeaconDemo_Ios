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
 1. If the app want to change the device paramaters, then it need connect to the device.
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
After the app connect to KBeacon success. The KBeacon will automatically read current paramaters from physical device. so the app can update UI and show the paramaters to user after connection setup.  
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

After app connect to device success, the app can update update paramaters of physical device.
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

Sometimes the app need to configure multiple parameters at the same time. We recommend that the app should check whether the parameters was changed before update. If the paramaters value is no change, the app do not need to send the configuration.  
Example2: check if the paramaters was changed, then send new paramaters to device
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
```

#### 4.3.4 Send command to device
After app connect to device success, the app can send command to device.
#### 4.3.4.1 Ring device
 For some KBeacon device that has buzzer function. The app can ring device. for ring command, it has 5 paramaters:
 * msg: msg type is 'ring'
 * ringTime: uint is ms. The KBeacon will start flash/alert for 'ringTime' millisecond  when receive this command.
 * ringType: 0x0:led flash only; 0x1:beep alert only; 0x2 both led flash and beep;
 * ledOn: optional paramaters, uint is ms.the LED will flash at interval (ledOn + ledOff).  This paramaters is valid when ringType set to 0x0 or 0x2.
 * ledOff: optional paramaters, uint is ms. the LED will flash at interval (ledOn + ledOff).  This paramaters is valid when ringType set to 0x0 or 0x2.

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

## 5. Change log
* 2019.10.11 v1.1 add KSesnor function
* 2019.4.1 v1.0 first version;