//
//  KBFirmwareDownload.m
//  KBeacon
//
//  Created by hogen on 2020/6/4.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBFirmwareDownload.h"
#import "AFNetworking-umbrella.h"

#define HEX_PATH_NAME @"KBeaconFirmware"
#define DEFAULT_DOWNLOAD_WEB_ADDRESS @"https://api.ieasygroup.com:8092/KBeaconFirmware/"


@implementation KBFirmwareDownload

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.firmwareWebAddress = DEFAULT_DOWNLOAD_WEB_ADDRESS;
    }
    return self;
}

-(NSString*)makeSureFileDirectory:(NSString*)name
{
    NSFileManager* fileManager = [[NSFileManager alloc]init];
    NSString* pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES)objectAtIndex:0];
    NSString*createPath = [NSString stringWithFormat:@"%@/%@",pathDocuments, name];
    
    if(![[NSFileManager defaultManager]fileExistsAtPath:createPath])
    {
        if ([fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil])
        {
            return createPath;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        NSLog(@"already has directory");
        return createPath;
    }
}

-(void) downloadFirmwareInfo:(NSString*)beaconModel callback:(onHttpFirmwareInfoDownCallback)callback
{
    NSString * urlStr = [NSString stringWithFormat:@"%@.json", beaconModel];
    
    [self downLoadFirmwreData:urlStr callback:^(BOOL bConfigSuccess, NSURL * _Nullable url, NSError * _Nullable error) {
        if (!bConfigSuccess)
        {
            callback(false, nil, error);
        }
        else
        {
            NSError* error;
            NSStringEncoding encoding = NSUTF8StringEncoding;
            NSString *resultData = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error];
            if (error == nil)
            {
                NSData *jsonData = [resultData dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
                callback(true, dict, nil);
            }
        }
    }];
}

-(void) downLoadFirmwreData:(NSString*) urlFileName callback:(onHttpFirmwareDataDownComplete)callback
{
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSString * urlStr = [NSString stringWithFormat:@"%@%@", self.firmwareWebAddress, urlFileName];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSString *filePath = [self makeSureFileDirectory: HEX_PATH_NAME];
    if (filePath == nil)
    {
        return;
    }
    NSString *writeFilePath = [filePath stringByAppendingPathComponent:url.lastPathComponent];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress)
    {
        NSLog(@"Downloading %.0f％", downloadProgress.fractionCompleted * 100);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
        
        return [NSURL fileURLWithPath:writeFilePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
         NSLog(@"Download complete");
        if (error != nil)
        {
            callback(false, nil, error);
        }
        else
        {
            callback(true, filePath, nil);
        }
        
    }];
    [downloadTask resume];
}

@end
