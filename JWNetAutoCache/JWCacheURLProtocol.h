//
//  JWCacheURLProtocol.h
//  JWNetCache
//
//  Created by junwen.deng on 16/8/19.
//  Copyright © 2016年 junwen.deng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWCacheURLProtocol : NSURLProtocol<NSURLSessionDataDelegate>

@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *config;//config是全局的，所有的网络请求都用这个config

@property (readwrite, nonatomic, assign) NSInteger updateInterval;//相同的url地址请求，相隔大于等于updateInterval才会发出后台更新的网络请求，小于的话不发出请求。

+ (void)startListeningNetWorking;
+ (void)cancelListeningNetWorking;

@end
