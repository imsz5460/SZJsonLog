//
//  ViewController.m
//  SZJsonLogDemo
//
//  Created by shizhi on 2022/9/9.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self printDict];
}

- (void)printDict {
    
    NSArray *array = @[
        @"琴",
        @"棋",
        @"书",
        @"画"
    ];
    NSLog(@"数组：%@",array);
    
    NSDictionary *dict = @{
        @"name":@"大魔王",
        @"address":@"我是云南的，云南丽江的",
        @"info": @{
            @"nickName":@"小而白",
            @"blog":@"https://www.jianshu.com/u/399cc7c53fad",
            @"score":@(0.3),
            @"isSingle":@(YES)
        },
        @"爱好":array
    };
   
    NSLog(@"字典：%@",dict);
    
    
}

@end
