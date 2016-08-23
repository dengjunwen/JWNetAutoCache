//
//  ViewController.m
//  JWNetCache
//
//  Created by junwen.deng on 16/8/19.
//  Copyright © 2016年 junwen.deng. All rights reserved.
//

#import "ViewController.h"
#import "JWCacheURLProtocol.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [JWCacheURLProtocol startListeningNetWorking];
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webview];
    NSURL *URL = [NSURL URLWithString:@"https://m.taobao.com"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    [webview loadRequest:request];
    
    NSLog(@"---%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [JWCacheURLProtocol cancelListeningNetWorking];
//    });
//    [JWCacheURLProtocol cancelListeningNetWorking];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
