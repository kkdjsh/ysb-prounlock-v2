#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 绾疧C runtime Hook锛屼笉渚濊禆CydiaSubstrate锛屽叏鑳界鐩存帴鍔犺浇

static BOOL hook_isProEnable(id self, SEL _cmd) {
    return YES;
}

__attribute__((constructor))
static void ProUnlockInit(void) {
    @autoreleasepool {
        NSLog(@"[ProUnlock] v3 loading...");

        Class userClass = NSClassFromString(@"TtC5YSKit4User");
        if (!userClass) {
            userClass = NSClassFromString(@"User");
        }
        if (!userClass) {
            NSLog(@"[ProUnlock] ERROR: User class not found");
            return;
        }

        NSLog(@"[ProUnlock] Found class: %@", NSStringFromClass(userClass));

        SEL sel = @selector(isProEnable);
        Method m = class_getInstanceMethod(userClass, sel);
        if (!m) {
            NSLog(@"[ProUnlock] isProEnable not found, listing methods...");
            unsigned int count;
            Method *methods = class_copyMethodList(userClass, &count);
            for (unsigned int i = 0; i < count; i++) {
                NSString *n = NSStringFromSelector(method_getName(methods[i]));
                if ([n containsString:@"Pro"] || [n containsString:@"pro"] || [n containsString:@"Buy"] || [n containsString:@"buy"]) {
                    NSLog(@"[ProUnlock] method: %@", n);
                }
            }
            free(methods);
            return;
        }

        method_setImplementation(m, (IMP)hook_isProEnable);
        NSLog(@"[ProUnlock] SUCCESS: isProEnable hooked -> YES");
    }
}
