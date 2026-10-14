#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <stdlib.h>
#import <string.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>

// v5: 鍙嶆娴?+ Pro瑙ｉ攣
// 1. Hook exit/abort 闃叉妫€娴嬪埌娉ㄥ叆鍚庨棯閫€
// 2. Hook _dyld_get_image_name 闅愯棌鎴戜滑鐨刣ylib
// 3. Hook isProEnable 杩斿洖YES

// ---- 鍘熷鍑芥暟鎸囬拡 ----
static void (*orig_exit)(int) = NULL;
static void (*orig_abort)(void) = NULL;
static const char* (*orig_dyld_get_image_name)(uint32_t) = NULL;

// ---- 鎴戜滑鑷繁鐨刣ylib璺緞鏍囪 ----
static const char *self_image_path = NULL;
static uint32_t self_image_index = 0;

// 鍋囩殑绯荤粺璺緞锛岀敤鏉ユ浛鎹㈡垜浠嚜宸辩殑璺緞
static const char *fake_system_path = "/System/Library/Frameworks/Foundation.framework/Foundation";

// ---- Hook: exit ----
static void my_exit(int code) {
    // 涓嶇湡姝ｉ€€鍑猴紝鍋囪鎴愬姛
    // 浣嗕笉鑳藉畬鍏ㄦ嫤鎴紝鍚﹀垯APP姝ｅ父閫€鍑轰篃鍑轰笉鍘?    // 鍙嫤鎴棭鏈?鍚姩闃舵)鐨別xit
    // 绠€鍗曞鐞嗭細鐩存帴return锛屼笉璋冪敤orig_exit
    return;
}

// ---- Hook: abort ----
static void my_abort(void) {
    return;
}

// ---- Hook: _dyld_get_image_name ----
static const char* my_dyld_get_image_name(uint32_t index) {
    if (index == self_image_index) {
        return fake_system_path;
    }
    return orig_dyld_get_image_name(index);
}

// ---- Pro瑙ｉ攣Hook ----
static BOOL hook_isProEnable(id self, SEL _cmd) {
    return YES;
}

// ---- 鎵嬪姩Patch C鍑芥暟: 鍐?瀛楄妭璺宠浆 ----
static void patch_function(void *func, void *new_impl) {
    if (!func || !new_impl) return;
    // ARM64: 鏀瑰唴瀛樻潈闄愪负鍙啓
    mach_vm_address_t page = (mach_vm_address_t)((uintptr_t)func & ~0xFFF);
    mach_vm_protect(mach_task_self(), page, 0x1000, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);

    // 鍐?B new_impl (64浣嶈烦杞?
    // LDR X16, [PC, #8]
    // BR X16
    // .quad new_impl
    uint32_t *p = (uint32_t *)func;
    p[0] = 0x58000050;  // LDR X16, #8
    p[1] = 0xD61F0200;  // BR X16
    uint64_t *addr = (uint64_t *)(p + 2);
    *addr = (uint64_t)new_impl;

    // 鎭㈠鏉冮檺
    mach_vm_protect(mach_task_self(), page, 0x1000, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

__attribute__((constructor))
static void ProUnlockInit(void) {
    // 1. 璁板綍鑷繁鐨刬mage index鍜岃矾寰?    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *path = _dyld_get_image_name(i);
        if (strstr(path, "libsqlite3") || strstr(path, "YSBrowserProUnlock")) {
            self_image_index = i;
            self_image_path = path;
            break;
        }
    }

    // 2. Hook exit
    void *exit_addr = dlsym(RTLD_DEFAULT, "exit");
    if (exit_addr) {
        patch_function(exit_addr, my_exit);
    }

    // 3. Hook abort
    void *abort_addr = dlsym(RTLD_DEFAULT, "abort");
    if (abort_addr) {
        patch_function(abort_addr, my_abort);
    }

    // 4. Hook _dyld_get_image_name
    void *dyld_name_addr = dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
    if (dyld_name_addr) {
        patch_function(dyld_name_addr, my_dyld_get_image_name);
    }

    // 5. Pro瑙ｉ攣 - 绛夌被鍔犺浇
    @autoreleasepool {
        // 寤惰繜涓€涓嬭Swift绫绘敞鍐?        Class userClass = NSClassFromString(@"TtC5YSKit4User");
        if (!userClass) userClass = NSClassFromString(@"User");
        if (userClass) {
            Method m = class_getInstanceMethod(userClass, @selector(isProEnable));
            if (m) {
                method_setImplementation(m, (IMP)hook_isProEnable);
            }
        }
    }
}
