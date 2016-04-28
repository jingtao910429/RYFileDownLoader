//
//  FileDownLoader.h
//  RYFileDownLoader
//
//  Created by wwt on 16/4/26.
//  Copyright © 2016年 rongyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMProgressHUD.h"
#import "MMLinearProgressView.h"


//远程Webview压缩包名称
#define ZipName @"ManagerApp.zip"
//远程Webview压缩包存储及解压路径
#define ZipPath @"Pandora/apps"

//Monitor download progress
typedef void (^ProgressHandler)(double progress);

//Monitor download complete
typedef void (^CompletionHandler)();

//Monitor download error
typedef void (^FailureHandler)(NSError *error);

@interface FileDownLoader : NSObject

//DownLoad Remote URL
@property (nonatomic, copy) NSString *remoteURL;

//StorePath To DownLoad
@property (nonatomic, copy) NSString *destinationPath;

//CachePath To DownLoad
@property (nonatomic, copy) NSString *cachePath;

//Whether it is being downloaded
@property (nonatomic, readonly, getter = isDownloading) BOOL Downloading;


@property (nonatomic, copy) ProgressHandler   progressHandler;
@property (nonatomic, copy) CompletionHandler completionHandler;
@property (nonatomic, copy) FailureHandler    failureHandler;

- (void)startDownload;

@end
