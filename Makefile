THEOS_PACKAGE_SCHEME = rootless

TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = YSBrowser

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YSBrowserProUnlock

YSBrowserProUnlock_FILES = Tweak.x
YSBrowserProUnlock_CFLAGS = -fobjc-arc
YSBrowserProUnlock_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
