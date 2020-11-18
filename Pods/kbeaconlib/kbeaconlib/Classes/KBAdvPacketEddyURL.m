//
//  KBAdvEddyURL.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/17.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAdvPacketEddyURL.h"

#define EDDYSTONE_URL_ENCODING_MAX  14
#define EDDYSTONE_URL_PREFIX_MAX  4
char* eddystoneURLPrefix[EDDYSTONE_URL_PREFIX_MAX] = {"http://www.",
    "https://www.",
    "http://",
    "https://"};

char* eddystoneURLEncoding[EDDYSTONE_URL_ENCODING_MAX] = {
    ".com/",
    ".org/",
    ".edu/",
    ".net/",
    ".info/",
    ".biz/",
    ".gov/",
    ".com/",
    ".org/",
    ".edu/",
    ".net/",
    ".info/",
    ".biz/",
    ".gov/"
};

@implementation KBAdvPacketEddyURL

-(BOOL) parseAdvPacket:(const NSData*) data
{
    [super parseAdvPacket:data];
    
    int nSrvIndex = 0;
    Byte* pSrvData = (Byte*)[data bytes];
    if (pSrvData[nSrvIndex++] != 0x10)
    {
        return NO;
    }
    
    //ref tx power
    SignedByte byRefPower = pSrvData[nSrvIndex++];
    _refTxPower = [NSNumber numberWithInt: byRefPower];
    
    //url
    int nUrlDataLen = (int)data.length - 2;
    char urlCharDec[40] = "";
    int nDecLen = [KBAdvPacketEddyURL decodeURL:(char*)&pSrvData[nSrvIndex] len:nUrlDataLen urlDec:urlCharDec];
    if (nDecLen == 0)
    {
        _url = @"";
    }else{
        _url =[NSString stringWithUTF8String:urlCharDec];
    }
    
    return YES;
}

+(Byte) encodeURL:(char*)urlOrg urlEnc:(char*)urlEnc
{
    Byte i, j;
    Byte urlLen;
    Byte tokenLen = 0;
    
    urlLen = (Byte) strlen(urlOrg);
    
    // search for a matching prefix
    for (i = 0; i < EDDYSTONE_URL_PREFIX_MAX; i++)
    {
        tokenLen = strlen(eddystoneURLPrefix[i]);
        if (strncmp(eddystoneURLPrefix[i], urlOrg, tokenLen) == 0)
        {
            break;
        }
    }
    
    if (i == EDDYSTONE_URL_PREFIX_MAX)
    {
        return 0;       // wrong prefix
    }
    
    // use the matching prefix number
    urlEnc[0] = i;
    urlOrg += tokenLen;
    urlLen -= tokenLen;
    
    // search for a token to be encoded
    for (i = 0; i < urlLen; i++)
    {
        for (j = 0; j < EDDYSTONE_URL_ENCODING_MAX; j++)
        {
            tokenLen = strlen(eddystoneURLEncoding[j]);
            if (strncmp(eddystoneURLEncoding[j], urlOrg + i, tokenLen) == 0)
            {
                // matching part found
                break;
            }
        }
        
        if (j < EDDYSTONE_URL_ENCODING_MAX)
        {
            memcpy(&urlEnc[1], urlOrg, i);
            // use the encoded byte
            urlEnc[i + 1] = j;
            break;
        }
    }
    
    if (i < urlLen)
    {
        memcpy(&urlEnc[i + 2],
               urlOrg + i + tokenLen, urlLen - i - tokenLen);
        return urlLen - tokenLen + 2;
    }
    
    memcpy(&urlEnc[1], urlOrg, urlLen);
    return urlLen + 1;
}

+(int)decodeURL:(char*) urlOrg len:(int)nSrcLength urlDec:(char*) urlDec
{
    int i, j, k;
    int decIndex = 0;
    
    //first
    if (urlOrg[0] > EDDYSTONE_URL_PREFIX_MAX)
    {
        return 0;
    }
    
    //add url head
    char* urlPrefex = eddystoneURLPrefix[urlOrg[0]];
    int nPrefexLen = (int)strlen(urlPrefex);
    for (i = 0; i < nPrefexLen; i++)
    {
        urlDec[decIndex++] = urlPrefex[i];
    }
    
    //add middle web
    for (j = 1; j < nSrcLength; j++)
    {
        if (urlOrg[j] <= EDDYSTONE_URL_ENCODING_MAX)
        {
            char*urlSuffix = eddystoneURLEncoding[urlOrg[j]];
            int nSuffixLen = (int)strlen(urlSuffix);
            for (k = 0; k < nSuffixLen; k++)
            {
                urlDec[decIndex++] = urlSuffix[k];
            }
        }
        else
        {
            urlDec[decIndex++] = urlOrg[j];
        }
    }
    
    return decIndex;
}

-(KBAdvType) advType
{
    return KBAdvTypeEddyURL;
}

@end
