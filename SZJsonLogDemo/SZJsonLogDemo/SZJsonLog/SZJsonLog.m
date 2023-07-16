//
//  SZJsonLog.m
//  SZJsonLog
//  https://github.com/imsz5460/SZJsonLog
//

/*
 -将字典（NSDictionary）、数组（NSArray）转成JSON格式字符串输出到控制台。
 -正常显示中文。
 -不会丢失数据精度
 -Convert the NSDictionary and NSArray into JSON format strings and output them to the console
 */


#ifdef DEBUG

#import "SZJsonLog.h"
#import <objc/runtime.h>


#define SZFUNCTIONSWAPREGISTER \
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
    Class class = [self class];\
    sz_swizzleSelector(class, @selector(descriptionWithLocale:), @selector(szlog_descriptionWithLocale:));\
    sz_swizzleSelector(class, @selector(descriptionWithLocale:indent:), @selector(szlog_descriptionWithLocale:indent:));\
    sz_swizzleSelector(class, @selector(debugDescription), @selector(szlog_debugDescription));\
});


#pragma mark - swizzleMethod
static inline void sz_swizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static void sz_convertToJsonString(id obj, NSUInteger level, NSMutableString *desc, NSString *tab, NSString *key) {
    NSError *error = nil;
    NSObject *result = [NSJSONSerialization JSONObjectWithData:obj
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
    if (key) {
        key = [key stringByAppendingString:@" : "];
    } else {
        key = @"";
    }
    if (error == nil && result != nil) {
        if ([result isKindOfClass:[NSDictionary class]]
            || [result isKindOfClass:[NSArray class]]) {
            NSString *str = [((NSDictionary *)result) descriptionWithLocale:nil indent:level + 1];
            [desc appendFormat:@"%@\t%@,\n", tab, str];
        } else if ([result isKindOfClass:[NSString class]]) {
            [desc appendFormat:@"%@\t%@\"%@\",\n", tab, key, result];
        }
    } else {
        @try {
            NSString *str = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
            if (str != nil) {
                [desc appendFormat:@"%@\t%@\"%@\",\n", tab, key, str];
            } else {
                [desc appendFormat:@"%@\t%@%@,\n", tab, key, obj];
            }
        }
        @catch (NSException *exception) {
            [desc appendFormat:@"%@\t%@%@,\n", tab, key, obj];
        }
    }
}

#pragma mark - NSDictionary分类
@implementation NSDictionary (SZJsonLog)

- (NSString *)szlog_descriptionWithLocale:(id)locale {
    return [self descriptionWithLocale:locale indent:0];
}

- (NSString *)szlog_descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSMutableString *desc = [NSMutableString string];
    NSMutableString *tabString = [[NSMutableString alloc] initWithCapacity:level];
    for (NSUInteger i = 0; i < level; ++i) {
        [tabString appendString:@"\t"];
    }
    NSString *tab = @"";
    if (level > 0) {
        tab = tabString;
    }
    [desc appendString:@"{\n"];
    // 对字典排序
    NSArray *allkeys = [self.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (id k in allkeys) {
        id obj = [self objectForKey:k];
        NSString *key = k;
        if ([key isKindOfClass:[NSString class]]) {
            key = [NSString stringWithFormat:@"\"%@\"", key];
        }
        if ([obj isKindOfClass:[NSString class]]) {
            [desc appendFormat:@"%@\t%@: \"%@\",\n", tab, key, obj];
        } else if ([NSStringFromClass([obj class]) isEqualToString:@"__NSCFBoolean"]) {
            [desc appendFormat:@"%@\t%@: %s,\n", tab, key, [(NSNumber *)obj boolValue] ?"true": "false"];
        } else if ([obj isKindOfClass:[NSArray class]]
                   || [obj isKindOfClass:[NSDictionary class]]) {
            [desc appendFormat:@"%@\t%@: %@,\n", tab, key, [obj descriptionWithLocale:locale indent:level + 1]];
        } else if ([obj isKindOfClass:[NSData class]]) {
            // 如果是NSData类型，尝试去解析结果，以打印出可阅读的数据
            sz_convertToJsonString(obj, level, desc, tab, key);
        } else if ([obj isKindOfClass:[NSNull class]])  {
            [desc appendFormat:@"%@\t%@: null,\n", tab, key];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.maximumFractionDigits = 14;
            NSString *bStr = [formatter stringFromNumber:obj];
            bStr = [bStr stringByReplacingOccurrencesOfString:@"," withString:@""];
            [desc appendFormat:@"%@\t%@: %@,\n", tab, key, bStr];
        } else {
            [desc appendFormat:@"%@\t%@: %@,\n", tab, key, obj];
        }
    }
    // 查出最后一个,的范围
    NSRange range = [desc rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length) {
        // 删掉最后一个,
        [desc deleteCharactersInRange:range];
    }
    [desc appendFormat:@"%@}", tab];
    return desc;
}

- (NSString *)szlog_debugDescription {
    
    return [self descriptionWithLocale:nil indent:0];
}



+ (void)load {
    SZFUNCTIONSWAPREGISTER
}

@end


#pragma mark - NSArray分类
@implementation NSArray (SZJsonLog)

- (NSString *)szlog_descriptionWithLocale:(id)locale {
    return [self descriptionWithLocale:nil indent:0];
}

- (NSString *)szlog_descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSMutableString *desc = [NSMutableString string];
    NSMutableString *tabString = [[NSMutableString alloc] initWithCapacity:level];
    for (NSUInteger i = 0; i < level; ++i) {
        [tabString appendString:@"\t"];
    }
    NSString *tab = @"";
    if (level > 0) {
        tab = tabString;
    }
    [desc appendString:@"[\n"];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]]
            || [obj isKindOfClass:[NSArray class]]) {
            NSString *str = [obj descriptionWithLocale:locale indent:level + 1];
            [desc appendFormat:@"%@\t%@,\n", tab, str];
        } else if ([obj isKindOfClass:[NSString class]]) {
            [desc appendFormat:@"%@\t\"%@\",\n", tab, obj];
        } else if ([NSStringFromClass([obj class]) isEqualToString:@"__NSCFBoolean"]) {
            [desc appendFormat:@"%@\t%s,\n", tab, [(NSNumber *)obj boolValue] ?"true": "false"];
        } else if ([obj isKindOfClass:[NSData class]]) {
            // 如果是NSData类型，尝试去解析结果，以打印出可阅读的数据
            sz_convertToJsonString(obj, level, desc, tab, nil);
        } else if ([obj isKindOfClass:[NSNull class]])  {
            [desc appendFormat:@"%@\tnull,\n", tab];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.maximumFractionDigits = 14;
            NSString *bStr = [formatter stringFromNumber:obj];
            bStr = [bStr stringByReplacingOccurrencesOfString:@"," withString:@""];
            [desc appendFormat:@"%@\t%@,\n", tab, bStr];
        } else {
            [desc appendFormat:@"%@\t%@,\n", tab, obj];
        }
    }
    // 查出最后一个,的范围
    NSRange range = [desc rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length) {
        // 删掉最后一个,
        [desc deleteCharactersInRange:range];
    }
    [desc appendFormat:@"%@]", tab];
    return desc;
}

//控制台使用po打印的时候调用。
- (NSString *)szlog_debugDescription {
    return  [self descriptionWithLocale:nil indent:0];
}

+ (void)load {
    SZFUNCTIONSWAPREGISTER
}

@end

#endif

