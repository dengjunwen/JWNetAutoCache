//
//  JWCacheURLProtocol.m
//  JWNetCache
//
//  Created by junwen.deng on 16/8/19.
//  Copyright © 2016年 junwen.deng. All rights reserved.
//



#import "JWCacheURLProtocol.h"

@interface JWUrlCacheUtil : NSObject

@property (readwrite, nonatomic, strong) NSMutableDictionary *urlDict;//记录上一次url请求时间
+ (instancetype)instance;
@end

@implementation JWUrlCacheUtil

- (NSMutableDictionary *)urlDict{
    if (!_urlDict) {
        _urlDict = [NSMutableDictionary dictionary];
    }
    return _urlDict;
}


+ (instancetype)instance{
    static JWUrlCacheUtil *urlCacheUtil = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urlCacheUtil = [[JWUrlCacheUtil alloc] init];
    });
    return urlCacheUtil;
}

@end

static NSString * const URLProtocolAlreadyHandleKey = @"alreadyHandle";
static NSString * const checkUpdateInBgKey = @"checkUpdateInBg";

@interface JWCacheURLProtocol()

@property (readwrite, nonatomic, strong) NSURLSession *session;
@property (readwrite, nonatomic, strong) NSMutableData *data;
@property (readwrite, nonatomic, strong) NSURLResponse *response;

@end

#define DefaultUpdateInterval 3600
@implementation JWCacheURLProtocol

- (NSInteger)updateInterval{
    if (_updateInterval == 0) {
        //默认后台更新的时间为3600秒
        _updateInterval = DefaultUpdateInterval;
    }
    return _updateInterval;
}

+ (void)startListeningNetWorking{
    [NSURLProtocol registerClass:[JWCacheURLProtocol class]];
}

- (void)clearUrlDict{
    NSLog(@"清空urldir");
    [JWUrlCacheUtil instance].urlDict = nil;
}

+ (void)cancelListeningNetWorking{
    [NSURLProtocol unregisterClass:[JWCacheURLProtocol class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSString *urlScheme = [[request URL] scheme];
    if ([urlScheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [urlScheme caseInsensitiveCompare:@"https"] == NSOrderedSame){
        //判断是否标记过使用缓存来处理，或者是否有标记后台更新
        if ([NSURLProtocol propertyForKey:URLProtocolAlreadyHandleKey inRequest:request] || [NSURLProtocol propertyForKey:checkUpdateInBgKey inRequest:request]) {
            return NO;
        }
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    return request;
}

- (void)backgroundCheckUpdate{
    
    dispatch_queue_t queue = dispatch_queue_create("cache.junwen.com", NULL);
    dispatch_async(queue, ^{
        NSDate *updateDate = [[JWUrlCacheUtil instance].urlDict objectForKey:self.request.URL.absoluteString];
        if (updateDate) {
            //判读两次相同的url地址发出请求相隔的时间，如果相隔的时间小于给定的时间，不发出请求。否则发出网络请求
            NSDate *currentDate = [NSDate date];
            NSInteger interval = [currentDate timeIntervalSinceDate:updateDate];
            if (interval < self.updateInterval) {
                return;
            }
        }
        NSMutableURLRequest *mutableRequest = [[self request] mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:checkUpdateInBgKey inRequest:mutableRequest];
        [self netRequestWithRequest:mutableRequest];
    });
}

- (void)netRequestWithRequest:(NSURLRequest *)request{
    if (!self.config) {
        self.config = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    self.session = [NSURLSession sessionWithConfiguration:self.config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask * sessionTask = [self.session dataTaskWithRequest:request];
    [sessionTask resume];
    [[JWUrlCacheUtil instance].urlDict setValue:[NSDate date] forKey:self.request.URL.absoluteString];
}


- (void)startLoading{
    NSCachedURLResponse *urlResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:[self request]];
    if (urlResponse) {
        //如果缓存存在，则使用缓存。并且开启异步线程去更新缓存
        [self.client URLProtocol:self didReceiveResponse:urlResponse.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:urlResponse.data];
        [self.client URLProtocolDidFinishLoading:self];
        [self backgroundCheckUpdate];
        return;
    }
    NSMutableURLRequest *mutableRequest = [[self request] mutableCopy];
    
    [NSURLProtocol setProperty:@YES forKey:URLProtocolAlreadyHandleKey inRequest:mutableRequest];
    
    [self netRequestWithRequest:mutableRequest];
}

- (void)stopLoading{
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (BOOL)isUseCache{
    //如果有缓存则使用缓存，没有缓存则发出请求
    
    return YES;
}

- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}
#pragma mark -NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.client URLProtocol:self didLoadData:data];
    
    [self appendData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    self.response = response;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
        if (!self.data) {
            return;
        }
        NSCachedURLResponse *cacheUrlResponse = [[NSCachedURLResponse alloc] initWithResponse:task.response data:self.data];
        [[NSURLCache sharedURLCache] storeCachedResponse:cacheUrlResponse forRequest:self.request];
        self.data = nil;
    }
}




@end
