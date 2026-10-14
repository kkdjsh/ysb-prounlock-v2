#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <stdlib.h>
#import <string.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

// v5: 鍙嶆娴?+ Pro瑙ｉ攣

static const char *fake_system_path = "/System/Library/Frameworks/Foundation.framework/Foundation";
static uint32_t self_image_index = 0;
static const char* (*orig_dyld_get_image_name)(uint32_t) = NULL;

static void my_exit(int code) { return; }
static void my_abort(void) { return; }

static const char* my_dyld_get_image_name(uint32_t index) {
    if (index == self_image_index) return fake_system_path;
    return orig_dyld_get_image_name(index);
}

static BOOL hook_isProEnable(id self, SEL _cmd) {
    return YES;
}

static void patch_function(void *func, void *new_impl) {
    if (!func || !new_impl) return;
    mach_vm_address_t page = (mach_vm_address_t)((uintptr_t)func & ~0xFFF);
    mach_vm_protect(mach_task_self(), page, 0x1000, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    uint32_t *p = (uint32_t *)func;
    p[0] = 0x58000050;
    p[1] = 0xD61F0200;
    uint64_t *addr = (uint64_t *)(p + 2);
    *addr = (uint64_t)new_impl;
    mach_vm_protect(mach_task_self(), page, 0x1000, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

__attribute__((constructor))
static void ProUnlockInit(void) {
    // 1. 璁板綍鑷繁鐨刬mage index
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *path = _dyld_get_image_name(i);
        if (strstr(path, "libsqlite3") || strstr(path, "YSBrowserProUnlock")) {
            self_image_index = i;
            break;
        }
    }

    // 2. Hook exit
    void *exit_addr = dlsym(RTLD_DEFAULT, "exit");
    if (exit_addr) patch_function(exit_addr, my_exit);

    // 3. Hook abort
    void *abort_addr = dlsym(RTLD_DEFAULT, "abort");
    if (abort_addr) patch_function(abort_addr, my_abort);

    // 4. Hook _dyld_get_image_name
    void *dyld_name_addr = dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
    if (dyld_name_addr) {
        orig_dyld_get_image_name = dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
        patch_function(dyld_name_addr, my_dyld_get_image_name);
    }

    // 5. Pro瑙ｉ攣
    @autoreleasepool {
        Class userClass = NSClassFromString(@"TtC5YSKit4User");
        if (!userClass) userClass = NSClassFromString(@"User");
        if (userClass) {
            Method m = class_getInstanceMethod(userClass, @selector(isProEnable));
            if (m) method_setImplementation(m, (IMP)hook_isProEnable);
        }
    }
}
