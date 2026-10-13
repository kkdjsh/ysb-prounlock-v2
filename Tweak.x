#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// 鏈€灏忓寲Pro瑙ｉ攣 - 鍙狧ook鏈€鏍稿績鐨勬柟娉曪紝閬垮厤绛惧悕涓嶅尮閰嶉棯閫€

static BOOL (*orig_isProEnable)(id self, SEL _cmd);

static BOOL new_isProEnable(id self, SEL _cmd) {
    NSLog(@"[ProUnlock] isProEnable called, returning YES");
    return YES;
}

%ctor {
    @autoreleasepool {
        NSLog(@"[ProUnlock] Tweak loaded, hooking...");

        @autoreleasepool {
            Class userClass = NSClassFromString(@"TtC5YSKit4User");
            if (userClass) {
                NSLog(@"[ProUnlock] Found class: %@", NSStringFromClass(userClass));

                Method m = class_getInstanceMethod(userClass, @selector(isProEnable));
                if (m) {
                    NSLog(@"[ProUnlock] Found isProEnable method, hooking...");
                    MSHookMessageEx(objc_getClass("TtC5YSKit4User"), @selector(isProEnable), (IMP)new_isProEnable, (IMP *)&orig_isProEnable);
                    NSLog(@"[ProUnlock] Hook success!");
                } else {
                    NSLog(@"[ProUnlock] WARNING: isProEnable method not found, trying property...");
                    // Try to list all methods for debug
                    unsigned int count;
                    Method *methods = class_copyMethodList(userClass, &count);
                    for (unsigned int i = 0; i < count; i++) {
                        SEL sel = method_getName(methods[i]);
                        NSString *selName = NSStringFromSelector(sel);
                        if ([selName containsString:@"Pro"] || [selName containsString:@"pro"] || [selName containsString:@"Buy"] || [selName containsString:@"buy"]) {
                            NSLog(@"[ProUnlock] Found method: %@", selName);
                        }
                    }
                    free(methods);
                }
            } else {
                NSLog(@"[ProUnlock] WARNING: TtC5YSKit4User class not found");
            }
        }
    }
}
