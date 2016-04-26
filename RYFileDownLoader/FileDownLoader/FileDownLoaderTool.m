//
//  FileDownLoaderTool.m
//  RYFileDownLoader
//
//  Created by wwt on 16/4/26.
//  Copyright © 2016年 rongyu. All rights reserved.
//

#import "FileDownLoaderTool.h"

@implementation FileDownLoaderTool

+ (BOOL)deleteFileWithPath:(NSString *)path
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
