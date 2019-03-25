LOCAL_PATH := $(call my-dir)

#----------------------------------------------------------------------
# Compile (L)ittle (K)ernel bootloader and the nandwrite utility
#----------------------------------------------------------------------
ifneq ($(strip $(TARGET_NO_BOOTLOADER)),true)

# Compile
include bootable/bootloader/edk2/AndroidBoot.mk

$(INSTALLED_BOOTLOADER_MODULE): $(TARGET_EMMC_BOOTLOADER) | $(ACP)
	$(transform-prebuilt-to-target)
$(BUILT_TARGET_FILES_PACKAGE): $(INSTALLED_BOOTLOADER_MODULE)

droidcore: $(INSTALLED_BOOTLOADER_MODULE)
droidcore_non_system: $(INSTALLED_BOOTLOADER_MODULE)
endif

#----------------------------------------------------------------------
# Compile Linux Kernel
#----------------------------------------------------------------------
ifeq ($(KERNEL_DEFCONFIG),)
    ifeq ($(TARGET_BUILD_VARIANT),user)
        KERNEL_DEFCONFIG := vendor/sdmsteppe-perf_defconfig
    else
        KERNEL_DEFCONFIG := vendor/sdmsteppe_defconfig
    endif
endif

ifeq ($(TARGET_KERNEL_SOURCE),)
     TARGET_KERNEL_SOURCE := kernel
endif

DTC := $(HOST_OUT_EXECUTABLES)/dtc$(HOST_EXECUTABLE_SUFFIX)
UFDT_APPLY_OVERLAY := $(HOST_OUT_EXECUTABLES)/ufdt_apply_overlay$(HOST_EXECUTABLE_SUFFIX)
TEMP_TOP=$(shell pwd)
TARGET_KERNEL_MAKE_ENV := DTC_EXT=$(TEMP_TOP)/$(DTC)
TARGET_KERNEL_MAKE_ENV += DTC_OVERLAY_TEST_EXT=$(TEMP_TOP)/$(UFDT_APPLY_OVERLAY)
TARGET_KERNEL_MAKE_ENV += CONFIG_BUILD_ARM64_DT_OVERLAY=y
TARGET_KERNEL_MAKE_ENV += HOSTCC=$(TEMP_TOP)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8/bin/x86_64-linux-gcc
TARGET_KERNEL_MAKE_ENV += HOSTAR=$(TEMP_TOP)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8/bin/x86_64-linux-ar
TARGET_KERNEL_MAKE_ENV += HOSTLD=$(TEMP_TOP)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8/bin/x86_64-linux-ld
TARGET_KERNEL_MAKE_ENV += HOSTCFLAGS="-I$$(pwd)/kernel/msm-4.14/include/uapi -I/usr/include -I/usr/include/x86_64-linux-gnu -L/usr/lib -L/usr/lib/x86_64-linux-gnu"
TARGET_KERNEL_MAKE_ENV += HOSTLDFLAGS="-L/usr/lib -L/usr/lib/x86_64-linux-gnu"

#Enable llvm support for kernel
KERNEL_LLVM_SUPPORT := true

#Enable sd-llvm suppport for kernel
KERNEL_SD_LLVM_SUPPORT := true

ifneq (, $(wildcard $(shell pwd)/prebuilts/build-tools/linux-x86/bin/make))
    MAKE := $(shell pwd)/prebuilts/build-tools/linux-x86/bin/$(MAKE)
endif

include $(TARGET_KERNEL_SOURCE)/AndroidKernel.mk
$(TARGET_PREBUILT_KERNEL): $(DTC) $(UFDT_APPLY_OVERLAY)

$(INSTALLED_KERNEL_TARGET): $(TARGET_PREBUILT_KERNEL) | $(ACP)
	$(transform-prebuilt-to-target)

#----------------------------------------------------------------------
# Copy additional target-specific files
#----------------------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_MODULE       := vold.fstab
LOCAL_MODULE_TAGS  := optional eng
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES    := $(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := init.target.rc
LOCAL_MODULE_TAGS  := optional eng
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES    := $(LOCAL_MODULE)
LOCAL_MODULE_PATH  := $(TARGET_OUT_VENDOR_ETC)/init/hw
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := gpio-keys.kl
LOCAL_MODULE_TAGS  := optional eng
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES    := $(LOCAL_MODULE)
LOCAL_MODULE_PATH  := $(TARGET_OUT_KEYLAYOUT)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := fstab.qcom
LOCAL_MODULE_TAGS  := optional eng
LOCAL_MODULE_CLASS := ETC
ifeq ($(ENABLE_AB), true)
LOCAL_SRC_FILES    := fstab_AB_variant.qti
else
LOCAL_SRC_FILES    := fstab_non_AB_variant.qti
endif
LOCAL_MODULE_PATH  := $(TARGET_OUT_VENDOR_ETC)
include $(BUILD_PREBUILT)

#----------------------------------------------------------------------
# Radio image
#----------------------------------------------------------------------
ifeq ($(ADD_RADIO_FILES), true)
radio_dir := $(LOCAL_PATH)/radio
RADIO_FILES := $(shell cd $(radio_dir) ; ls)
$(foreach f, $(RADIO_FILES), \
	$(call add-radio-file,radio/$(f)))
endif

#----------------------------------------------------------------------
# extra images
#----------------------------------------------------------------------
#ifeq (, $(wildcard vendor/qcom/build/tasks/generate_extra_images.mk))
include device/qcom/common/generate_extra_images.mk
#endif

#----------------------------------------------------------------------
# wlan specific
#----------------------------------------------------------------------
ifeq ($(strip $(BOARD_HAS_QCOM_WLAN)),true)
include device/qcom/wlan/talos/AndroidBoardWlan.mk
endif
