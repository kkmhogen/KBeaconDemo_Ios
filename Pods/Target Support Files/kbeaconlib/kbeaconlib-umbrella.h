#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "KBAdvPacketBase.h"
#import "KBAdvPacketEddyTLM.h"
#import "KBAdvPacketEddyUID.h"
#import "KBAdvPacketEddyURL.h"
#import "KBAdvPacketHandler.h"
#import "KBAdvPacketIBeacon.h"
#import "KBAdvPacketSensor.h"
#import "KBAuthHandler.h"
#import "KBCfgBase.h"
#import "KBCfgCommon.h"
#import "KBCfgEddyUID.h"
#import "KBCfgEddyURL.h"
#import "KBCfgHandler.h"
#import "KBCfgHumidityTrigger.h"
#import "KBCfgIBeacon.h"
#import "KBCfgNearbyTrigger.h"
#import "KBCfgSensor.h"
#import "KBCfgSleepTime.h"
#import "KBCfgTrigger.h"
#import "KBConnPara.h"
#import "KBeacon.h"
#import "KBeaconsMgr.h"
#import "KBException.h"
#import "KBHumidityDataMsg.h"
#import "KBHumidityNotifyData.h"
#import "KBHumidityRecord.h"
#import "KBNotifyButtonEvtData.h"
#import "KBNotifyData.h"
#import "KBNotifyDataBase.h"
#import "KBNotifyMotionEvtData.h"
#import "KBProximityDataMsg.h"
#import "KBProximityNotifyData.h"
#import "KBProximityRecord.h"
#import "KBSensorDataMsgBase.h"
#import "KBSubscribeNotifyItem.h"
#import "KBUtility.h"
#import "UTCTime.h"

FOUNDATION_EXPORT double kbeaconlibVersionNumber;
FOUNDATION_EXPORT const unsigned char kbeaconlibVersionString[];

