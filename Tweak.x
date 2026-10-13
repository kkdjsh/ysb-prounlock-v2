#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// YSBrowser Pro解锁 Tweak
// 目标类: YSKit.User (OC runtime名: TtC5YSKit4User)
// Hook核心Pro/VIP判断方法，强制返回已购买/已激活状态

%hook TtC5YSKit4User

// Pro功能开关 - 强制返回YES
- (BOOL)isProEnable {
    return YES;
}

// App是否过期 - 强制返回NO（永不过期）
- (BOOL)isAppExp {
    return NO;
}

// 98元买断标记 - 强制返回YES
- (BOOL)isBuy98 {
    return YES;
}

// 会员状态标记 - 强制返回YES
- (BOOL)ishs {
    return YES;
}

// 是否检查Pro - 返回NO（跳过Pro状态检查）
- (BOOL)isCheckPro {
    return NO;
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[YSBrowser ProUnlock] Tweak loaded successfully");
    }
}
