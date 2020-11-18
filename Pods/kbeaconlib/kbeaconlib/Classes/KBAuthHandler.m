//
//  KBAuthHandler.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/28.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAuthHandler.h"
#import "KBUtility.h"
#import "CommonCrypto/CommonDigest.h"

//auth
#define AUTH_PHASE1_APP 0x1
#define AUTH_PHASE2_DEV 0x2
#define AUTH_MIN_MTU_ALOGRIM_PH1  11
#define AUTH_MIN_MTU_SIMP_ALOGRIM_PH2 12

#define AUTH_PASSWORD_LEN 16
#define AUTH_FACTOR_ID_1 0xA9
#define AUTH_FACTOR_ID_2 0xB1

@implementation KBAuthHandler
{
    Byte mAuthPhase1AppRandom[4];
    Byte mAuthDeviceMac[6];
    NSString* mPassword;
    KBConnPara* mConnPara;
}

-(id) init
{
    self = [super init];
    
    _mtuSize = [NSNumber numberWithInt:20];
    
    return self;
}

-(void)setConnPara:(KBConnPara*)connPara
{
    mConnPara = connPara;
}


//send md5 requet
-(BOOL) authSendMd5Request:(NSString*)macAddress password:(NSString*)password
{
    NSString* strMacAddress = [macAddress stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSData* macData = [KBUtility hexStringToBytes:strMacAddress];
    if (macData.length != 6)
    {
        NSLog(@"mac address length failed");
        return NO;
    }
    [macData getBytes:mAuthDeviceMac length:6];
    Byte byReverseMac[6];
    memcpy(byReverseMac, mAuthDeviceMac, 6);
    mAuthDeviceMac[0] = byReverseMac[5];
    mAuthDeviceMac[1] = byReverseMac[4];
    mAuthDeviceMac[2] = byReverseMac[3];
    mAuthDeviceMac[3] = byReverseMac[2];
    mAuthDeviceMac[4] = byReverseMac[1];
    mAuthDeviceMac[5] = byReverseMac[0];
    

    if (password.length < 8 || password.length > 16)
    {
        NSLog(@"Password length failed");
        return NO;
    }
    mPassword = password;
    
    //add message head
    NSMutableData *nsWriteData = [[NSMutableData alloc]init];
    Byte authRequest[6] = {0};
    authRequest[0] = 0x13;
    authRequest[1] = AUTH_PHASE1_APP;
    int nRandom = arc4random();
    authRequest[2] = mAuthPhase1AppRandom[0] = (nRandom >> 24) & 0xFF;
    authRequest[3] = mAuthPhase1AppRandom[1] = (nRandom >> 16) & 0xFF;
    authRequest[4] = mAuthPhase1AppRandom[2] = (nRandom >> 8) & 0xFF;
    authRequest[5] = mAuthPhase1AppRandom[3] = nRandom & 0xFF;
    [nsWriteData appendBytes:(void*)authRequest length:6];
    
    //add utc time
    if (mConnPara != nil)
    {
        Byte byUtcTime[4];
        byUtcTime[0] = (mConnPara.utcTime >> 24) & 0xFF;
        byUtcTime[1] = (mConnPara.utcTime >> 16) & 0xFF;
        byUtcTime[2] = (mConnPara.utcTime >> 8) & 0xFF;
        byUtcTime[3] = (mConnPara.utcTime & 0xFF);
        [nsWriteData appendBytes:(void*)byUtcTime length:4];
    }
        
    [self.delegate writeAuthData:nsWriteData];
    
    return YES;
}

-(void) authHandleResponse:(Byte*)byRcvNtfValue lenght:(int)authDataLen
{
    if (authDataLen < 1)
    {
        [self.delegate authStateChange:KBAuthFailed];
    }
    
    if (byRcvNtfValue[0] == AUTH_PHASE1_APP || byRcvNtfValue[0] == AUTH_MIN_MTU_ALOGRIM_PH1)
    {
        if (![self authHandlePhase1Response: &byRcvNtfValue[1] lenght:authDataLen-1
              shortAuth:(byRcvNtfValue[0] == AUTH_MIN_MTU_ALOGRIM_PH1)])
        {
            [self.delegate authStateChange:KBAuthFailed];
        }
    }
    else if (byRcvNtfValue[0] == AUTH_PHASE2_DEV)
    {
        if (authDataLen >= 2)
        {
            _mtuSize = [NSNumber numberWithInteger: byRcvNtfValue[1]-3];
        }
        
        NSData* macData = [[NSData alloc] initWithBytes:mAuthDeviceMac length:6];
        NSLog(@"Device(%@) auth success, mtu:%d",
              [KBUtility bytesToHexString:macData],
              [_mtuSize intValue]);
        [self.delegate authStateChange:KBAuthSuccess];
    }
}

-(BOOL) authHandlePhase1Response:(Byte*)byRcvNtfValue lenght:(int)authDataLen shortAuth:(BOOL)isShortAuth
{
    unsigned char nFactorID[2] = {AUTH_FACTOR_ID_1, AUTH_FACTOR_ID_2};
    Byte md5Source[30];
    NSMutableData *auth1AppMd5Data = [[NSMutableData alloc]init];
    Byte byAuth1AppMd5Result[16];
    NSMutableData *auth2DevMd5Data = [[NSMutableData alloc]init];
    Byte byAuth2DevMd5Result[16];
    
    
    //check input valid
    if (isShortAuth)
    {
        if (authDataLen < 12)
        {
            return false;
        }
    }else{
        if (authDataLen < 20)
        {
            return false;
        }
    }
    
    if (mPassword == nil)
    {
        NSLog(@"not found password");
        return false;
    }
    NSData *nsPasswordData = [mPassword dataUsingEncoding: NSUTF8StringEncoding];
    
    //verify auth value
    [auth1AppMd5Data appendBytes:mAuthDeviceMac length: 6];
    [auth1AppMd5Data appendBytes:nFactorID length: 2];
    [auth1AppMd5Data appendBytes:mAuthPhase1AppRandom length: 4];
    [auth1AppMd5Data appendData:nsPasswordData];
    [auth1AppMd5Data getBytes:md5Source length:auth1AppMd5Data.length];
    CC_MD5(md5Source, (int)auth1AppMd5Data.length, byAuth1AppMd5Result);
    
    if (isShortAuth)
    {
        Byte byShortMd5Result[8];
        for (int i = 0; i < 8; i++)
        {
            byShortMd5Result[i] = (Byte)((byAuth1AppMd5Result[i] ^ byAuth1AppMd5Result[8+i]) & 0xFF);
        }
        if (memcmp(byShortMd5Result, &byRcvNtfValue[4], 8) != 0)
        {
            return false;
        }
    }
    else
    {
        if (memcmp(byAuth1AppMd5Result, &byRcvNtfValue[4], 16) != 0)
        {
            return false;
        }
    }
    
    //get auth2 md5 value
    [auth2DevMd5Data appendBytes:mAuthDeviceMac length: 6];
    [auth2DevMd5Data appendBytes:nFactorID length: 2];
    [auth2DevMd5Data appendBytes:byRcvNtfValue length: 4];
    [auth2DevMd5Data appendData:nsPasswordData];
    [auth2DevMd5Data getBytes:md5Source length:auth1AppMd5Data.length];
    CC_MD5(md5Source, (int)auth2DevMd5Data.length, byAuth2DevMd5Result);
    
    //send auth2 md5 response
    Byte authRequest[18] = {0};
    authRequest[0] = 0x13;
    NSData *nsWriteData;
    if (isShortAuth)
    {
        authRequest[1] = AUTH_MIN_MTU_SIMP_ALOGRIM_PH2;
        for (int i = 0; i < 8; i++)
        {
            authRequest[i+2] = (Byte)((byAuth2DevMd5Result[i] ^ byAuth2DevMd5Result[i + 8]) & 0xFF);
        }
        nsWriteData = [[NSData alloc] initWithBytes:authRequest length:10];
    }
    else
    {
        authRequest[1] = AUTH_PHASE2_DEV;
        for (int i = 0; i < 16; i++)
        {
            authRequest[i+2] = byAuth2DevMd5Result[i];
        }
        nsWriteData = [[NSData alloc] initWithBytes:authRequest length:18];
    }
    [self.delegate writeAuthData:nsWriteData];
    
    return true;
}

@end
