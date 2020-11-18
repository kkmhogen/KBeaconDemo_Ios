//
//  ESLUtility.m
//  KBeaconConfig
//
//  Created by kkm on 2018/12/10.
//  Copyright © 2018 kkm. All rights reserved.
//

#import "KBUtility.h"


@implementation KBUtility


+(CBUUID*) CBUUID16ToCBUUID128:(CBUUID *)UUID16
{
    if (UUID16.data.length == 16)
    {
        return UUID16;
    }
    
    char uuid16[2];
    [UUID16.data getBytes:uuid16 length:2];
    
    NSString* uuidString = [NSString stringWithFormat:@"0000%02x%02x-0000-1000-8000-00805f9b34fb",
                            (Byte)uuid16[0], (Byte)(uuid16[1] & 0xFF)];
    
    return [CBUUID UUIDWithString:uuidString];
}

+(CBService *) findServiceFromUUID:(CBPeripheral*) periperial cbuuID: (CBUUID *)UUID
{
    for(int i = 0; i < periperial.services.count; i++)
    {
        CBService *s = [periperial.services objectAtIndex:i];
        if ([s.UUID isEqual:UUID])
        {
            return s;
        }
    }
    return nil;
}

+(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([c.UUID isEqual:UUID])
        {
            return c;
        }
    }
    return nil; //Characteristic not found on this service
}

+(NSString*)bytesToHexString:(NSData*)data
{
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

+(NSData*) hexStringToBytes: (NSString*) hexString
{
    NSString *newStr = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (![KBUtility isHexString:hexString])
    {
        return nil;
    }
    
    const char *hexChar = [newStr UTF8String];
    Byte *bt = malloc(sizeof(Byte)*(newStr.length/2));
    
    char tmpChar[3] = {'\0','\0','\0'};
    int btIndex = 0;
    
    for (int i=0; i < newStr.length; i += 2)
    {
        tmpChar[0] = hexChar[i];
        tmpChar[1] = hexChar[i+1];
        bt[btIndex] = strtoul(tmpChar, NULL, 16);
        btIndex++;
    }
    
    NSData *data = [NSData dataWithBytes:bt length:btIndex];
    free(bt);
    
    return data;
}

+(NSString*)jsonData2StringWithoutSpaceReturn:(NSData*)jsonData
{
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    
    //remove space
    NSRange range = {0,jsonString.length};
    [mutStr replaceOccurrencesOfString:@" "withString:@""options:NSLiteralSearch range:range];
    
    //remove return
    NSRange range2 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n"withString:@""options:NSLiteralSearch range:range2];
    
    //remove esc
    NSRange range3 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\\"withString:@""options:NSLiteralSearch range:range3];
    
    return mutStr;
}



+(BOOL)isHexString:(NSString*)hexString
 {
     NSString* pattern = @"([0-9A-Fa-f]{2})+";
     NSString* pattern2 = @"^0X|^0x([0-9A-Fa-f]{2})+";
     
     NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
     if (![pred evaluateWithObject:hexString])
     {
         pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern2];
         if (![pred evaluateWithObject:hexString])
         {
             return NO;
         }
     }
     
     return YES;
 }

+(BOOL) isUUIDString:(NSString*)hexString
{
    NSString *hexRegex = @"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}";
    NSPredicate *hexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", hexRegex];
    
    return [hexTest evaluateWithObject:hexString];
}

+(NSString*) FormatHexUUID2User:(NSString*)strUUID
{
    NSString* strTempString = [strUUID uppercaseString];
    strTempString = [strTempString stringByReplacingOccurrencesOfString:@"0X" withString:@""];
    if ([strTempString length] != 32)
    {
        return @"";
    }

    NSString* strUserUUID, *strTempValue;
    strUserUUID = [strTempString substringWithRange: NSMakeRange(0,8)];

    strTempValue = [strTempString substringWithRange: NSMakeRange(8,12)];
    strUserUUID = [NSString stringWithFormat:@"%@-%@", strUserUUID, strTempValue];
    
    strTempValue = [strTempString substringWithRange: NSMakeRange(12,16)];
    strUserUUID = [NSString stringWithFormat:@"%@-%@", strUserUUID, strTempValue];
    
    strTempValue = [strTempString substringWithRange: NSMakeRange(16,20)];
    strUserUUID = [NSString stringWithFormat:@"%@-%@", strUserUUID, strTempValue];
    
    strTempValue = [strTempString substringWithRange: NSMakeRange(20,31)];
    strUserUUID = [NSString stringWithFormat:@"%@-%@", strUserUUID, strTempValue];

    return strUserUUID;
}

+(float)signedBytes2Float:(Byte)byte1 second:(Byte)byte2
{
    int nBytePointLeft = (char)byte1;
    float nBytePointRight = ((float)(byte2 & 0xFF)) / 256;
    float fResult = 0.0;
    if (nBytePointLeft < 0)
    {
        fResult = nBytePointLeft - nBytePointRight;
    }
    else
    {
        fResult = nBytePointLeft + nBytePointRight;
    }
    
    return fResult;
}


@end
