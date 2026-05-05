#
#  DYYY-Optimized
#
#  Copyright (c) 2024-2025 DYYY Team. All rights reserved.
#  Based on DYYY by huami
#
# 优化版本：修复已知问题，改进代码结构
#

# 本地配置文件（可选）
-include Makefile.local

# 关键构建配置 - 不要简化这些变量
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

# 打包方案选择
ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
else
    unexport THEOS_PACKAGE_SCHEME
endif

# GitHub Actions 环境配置
ifeq ($(GITHUB_ACTIONS),true)
    export INSTALL = 0
    export FINALPACKAGE = 1
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

# 源文件列表 - 按功能模块组织
DYYY_FILES = DYYY.xm DYYYSettings.xm DYYYIMEnhancement.xm DYYYABTestHook.xm DYYYLongPressPanel.xm DYYYFloatClearButton.xm DYYYManager.m DYYYSettingsHelper.m DYYYSettingViewController.m DYYYUtils.m DYYYToast.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYKeywordListView.m DYYYFilterSettingsView.m DYYYConfirmCloseView.m DYYYImagePickerDelegate.m DYYYBackupPickerDelegate.m DYYYFloatSpeedButton.m CityManager.m AWMSafeDispatchTimer.m

# 编译配置
DYYY_CFLAGS = -fobjc-arc -w
DYYY_LDFLAGS = -weak_framework AVFAudio
DYYY_FRAMEWORKS = CoreAudio
CXXFLAGS += -std=c++11
CCFLAGS += -std=c++11

# Logos 生成器配置
export THEOS_STRICT_LOGOS=0
export ERROR_ON_WARNINGS=0
export LOGOS_DEFAULT_GENERATOR=internal

include $(THEOS_MAKE_PATH)/tweak.mk

# 设备配置
THEOS_DEVICE_IP = 192.168.15.201
THEOS_DEVICE_PORT = 22

# 清理
clean::
	@echo "==> Cleaning packages..."
	@rm -rf .theos packages

# 编译并自动安装
after-package::
	@echo "==> Packaging complete."
