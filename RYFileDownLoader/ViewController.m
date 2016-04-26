//
//  ViewController.m
//  RYFileDownLoader
//
//  Created by wwt on 16/4/26.
//  Copyright © 2016年 rongyu. All rights reserved.
//

#import "ViewController.h"
#import "FileDownLoader.h"
#import "SSZipArchive.h"
#import "FileDownLoaderTool.h"

@interface ViewController ()

@property (nonatomic, strong) FileDownLoader *fileDownLoader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.fileDownLoader startDownload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - getters & setters

- (FileDownLoader *)fileDownLoader
{
    
    if (_fileDownLoader == nil) {
        
        _fileDownLoader = [[FileDownLoader alloc] init];
        
        //设置文件下载路径
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *appTime = [defaults objectForKey:@"lastModified"];
        
        //测试api_domain:801+/AppLocal/UpdateManagerApp?ticks=%@
        //NSString *domainStr = @"http://m.rongyu100.com";
        NSString *domainStr = @"https://192.168.253.33:4501";
        
        NSString *downLoadURL = [NSString stringWithFormat:@"%@/AppLocal/UpdateManagerApp?ticks=%@",domainStr,@""];
        
        if (appTime) {
            downLoadURL = [NSString stringWithFormat:@"%@/AppLocal/UpdateManagerApp?ticks=%@",domainStr,appTime];
        }
        
        _fileDownLoader.remoteURL = downLoadURL;
        
        //设置文件保存路径
        NSString *cachesPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:ZipPath];
        NSString *filePath = [cachesPath stringByAppendingPathComponent:ZipName];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:cachesPath]) {
            [fileManager createDirectoryAtPath:cachesPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        _fileDownLoader.destinationPath = filePath;
        
        _fileDownLoader.progressHandler = ^(double progress) {
            [MMProgressHUD updateProgress:progress];
        };
        _fileDownLoader.completionHandler = ^{
            [MMProgressHUD dismiss];
            //下载完成后，对文件进行解压
            [SSZipArchive unzipFileAtPath:filePath toDestination:cachesPath];
            [FileDownLoaderTool deleteFileWithPath:filePath];
        };
        _fileDownLoader.failureHandler = ^(NSError *error) {
            [MMProgressHUD dismissWithError:nil title:@"下载出错" afterDelay:0.2];
        };
    }
    return _fileDownLoader;
}

- (BOOL)deleteFileWithPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL ret = [fileManager fileExistsAtPath:path];
    if (ret) {
        NSError *error = nil;
        if ([fileManager removeItemAtPath:path error:&error]) {
            return YES;
        }
    }
    return NO;
}

@end
