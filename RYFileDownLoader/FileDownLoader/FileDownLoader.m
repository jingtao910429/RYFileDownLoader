//
//  FileDownLoader.m
//  RYFileDownLoader
//
//  Created by wwt on 16/4/26.
//  Copyright © 2016年 rongyu. All rights reserved.
//

#import "FileDownLoader.h"

#define TimeOut 6.0f
#define API_DOMAIN @"https://192.168.253.33:4501"

@interface FileDownLoader () <NSURLConnectionDataDelegate>

//文件句柄
@property (nonatomic, strong) NSFileHandle *writeHandle;
//当前获取到的数据长度
@property (nonatomic, assign) long long currentLength;
//完整数据长度
@property (nonatomic, assign) long long sumLength;

//证书校验URLConnection
@property (nonatomic, strong) NSURLConnection     *credentialConnection;
@property (nonatomic, strong) NSMutableURLRequest *credentialRequest;

@end

@implementation FileDownLoader

#pragma mark - life cycle

- (instancetype)init {
    if (self = [super init]) {
        [self initData];
    }
    return self;
}

#pragma mark - private methods

//数据初始化
- (void)initData {
    _Downloading = NO;
}

//开始下载
- (void)startDownload {
    
    if (_Downloading) {
        return;
    }
    
    _Downloading = YES;
    
    self.credentialRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.remoteURL] cachePolicy:0 timeoutInterval:TimeOut];
    self.credentialRequest.HTTPMethod = @"GET";
     //iOS9.0方法更换
    self.credentialConnection = [NSURLConnection connectionWithRequest:self.credentialRequest delegate:self];
    
    __block FileDownLoader *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:self.credentialRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *lastModifiedString = [[httpResponse allHeaderFields] objectForKey:@"LastModifiedTicks"];
        NSUInteger statusCode = httpResponse.statusCode;//状态码
        //本地缓存文件大小
        long long cacheFileSize = [self localFileSize];
        
        if (response == nil) {
            return;
        }
        
        if ( (statusCode == 304 || statusCode == 206) && cacheFileSize > 0 ) {
            
            NSLog(@"压缩包已经存在");
            return;
            
        } else {
            
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            
            [settings removeObjectForKey:@"lastModified"];
            [settings setObject:lastModifiedString forKey:@"lastModified"];
            [settings synchronize];
            
            [MMProgressHUD setProgressViewClass:[MMLinearProgressView class]];
            [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleFade];
            [MMProgressHUD showDeterminateProgressWithTitle:@"正在更新资源文件" status:nil];
            
            [NSURLConnection connectionWithRequest:weakSelf.credentialRequest delegate:weakSelf];
            
        }
        
    }];
}

//读取本地缓存文件大小
- (long long)localFileSize
{
    NSDictionary *fileAttributeDict = [[NSFileManager defaultManager] attributesOfItemAtPath:self.destinationPath error:NULL];
    return [fileAttributeDict[NSFileSize] longLongValue];
}

#pragma mark- NSURLConnectionDataDelegate代理方法
/*
 *当接收到服务器的响应（连通了服务器）时会调用
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (self.credentialConnection == connection) {
        return;
    }
    
    //判断是否是第一次连接
    if (self.sumLength) return;
    
    //1.创建文件存储路径
    /*
    NSString *cachesPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                            stringByAppendingPathComponent:ZipPath];
    NSString *filePath = [cachesPath stringByAppendingPathComponent:ZipName];
    */
    
    //2.如果文件夹已存在，先删除再创建
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:self.cachePath]) {
        [fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //3.创建一个空的文件到沙盒中
    if ([fileManager fileExistsAtPath:self.destinationPath]) {
        [fileManager removeItemAtPath:self.destinationPath error:nil];
        if (![fileManager fileExistsAtPath:self.destinationPath]) {
            [fileManager createFileAtPath:self.destinationPath contents:nil attributes:nil];
        }
    }else {
        [fileManager createFileAtPath:self.destinationPath contents:nil attributes:nil];
    }
    
    //4.创建写数据的文件句柄
    self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:self.destinationPath];
    
    //5.获取完整的文件长度
    self.sumLength = response.expectedContentLength;
}

/*
 *当接收到服务器的数据时会调用（可能会被调用多次，每次只传递部分数据）
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.credentialConnection == connection) {
        return;
    }
    
    //累加接收到的数据长度
    self.currentLength += data.length;
    //计算进度值
    double progress = (double)self.currentLength/self.sumLength;
    if (self.progressHandler) {//传递进度值给block
        self.progressHandler(progress);
    }
    
    //接收数据
    //把data写入到创建的空文件中，但是不能使用writeTofile(会覆盖)
    //移动到文件的尾部
    [self.writeHandle seekToEndOfFile];
    //从当前移动的位置，写入数据
    [self.writeHandle writeData:data];
}

/*
 *当服务器的数据加载完毕时就会调用
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.credentialConnection == connection) {
        return;
    }
    
    //关闭连接，不再输入数据在文件中
    [self.writeHandle closeFile];
    self.writeHandle = nil;
    
    //清空进度值
    self.currentLength = 0;
    self.sumLength = 0;
    
    _Downloading = NO;
    
    if (self.completionHandler) {//下载完成通知控制器
        self.completionHandler();
    }
}

/*
 *请求错误（失败）的时候调用（请求超时\断网\没有网\，一般指客户端错误）
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.credentialConnection == connection) {
        return;
    }
    
    _Downloading = NO;
    
    if (self.failureHandler) {//通知控制器，下载出错
        self.failureHandler(error);
    }
}


// to deal with self-signed certificates
- (BOOL) connection:(NSURLConnection *)connection
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void) connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod
         isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // we only trust our own domain
        
        NSArray *hostsArray = [API_DOMAIN componentsSeparatedByString:@":"];
        NSString *hostAllowStr = [hostsArray[1] substringFromIndex:[@"//" length]];
        
        if ([challenge.protectionSpace.host isEqualToString:hostAllowStr]) {
            SecTrustRef trust = challenge.protectionSpace.serverTrust;
            NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            //[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}


@end
