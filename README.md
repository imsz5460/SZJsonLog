# 字典或数组原生NSLog打印的问题
```objc
NSDictionary *dict = @{
        @"name":@"大魔王",
        @"address":@"我是云南的，云南丽江的",
        @"info": @{
            @"nickName":@"小而白",
            @"blog":@"https://www.jianshu.com/u/399cc7c53fad",
            @"score":@(0.3),
            @"isSingle":@(YES)
        }
    };
NSLog(@"字典：%@",dict);
```
>Xcode控制台上打印显示：
![默认情况下打印字典.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/7c9c96fde5a4482a9cf2ebe3137cb7fa~tplv-k3u1fbpfcp-watermark.image?)

默认的打印格式除了中文乱码以外，还有两个不容忽视的问题：
1. 字典中@"isSingle":@(YES)   BOOL类型的值被输出为1
2. 字典中@"score":@(0.3)  浮点数0.3被加上了引号变成了字符格式

# 解决方案
为了解决以上痛点，我查阅了相关资料，却没有找到一个十分满意的现成方案。于是一个轻量级的零侵入打印框架*SZJsonLog*应运而生。
>使用SZJsonLog后打印效果是这样的
![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/00baa6dac5b74520848541c5c3ae7097~tplv-k3u1fbpfcp-watermark.image?)

完美还原原始JSON数据。
下载后文件直接拖入工程，使用系统原生打印方法即可（无需手动调用该框架内方法）po命令同样适用。该框架仅在debug模式下生效。祝您享用愉快！
# Swift中如何使用？
很简单，拖入工程后，只需将swift中的Dictionary转换成NSDictionary来用即可。举个🌰
```        
var dict: [String : Any]  = [
            "key1" : true,
            "key2" : 0.3,
            "key3" : ["key1" : ["1",2,"中文","http://www.baidu.com"],
                      "key2": "value2"],
        ]
 print(dict as NSDictionary)
```
输出截图如下：
![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e576e76986dc403ba2184d4ab83fa393~tplv-k3u1fbpfcp-watermark.image?)

但swift项目中lldb po命令打印json格式失效。虽然不是json格式，还好打印键值对时不会像OC中一样数据失真。
