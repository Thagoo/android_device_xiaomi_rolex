# Copyright (C) 2017 The Android Open Source Project
# Copyright (C) 2017-2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifeq ($(TARGET_DEVICE),rolex)

LOCAL_PATH := $(call my-dir)

ifeq ($(call is-vendor-board-platform,QCOM),true)

include $(CLEAR_VARS)

LOCAL_MODULE_RELATIVE_PATH := hw

LOCAL_SHARED_LIBRARIES := \
    liblog \
    libcutils \
    libdl \
    libbase \
    libutils \
    android.hardware.power-ndk_platform \
    libbinder_ndk

LOCAL_SRC_FILES := \
    power-common.c \
    metadata-parser.c \
    utils.c \
    list.c \
    hint-data.c \
    Power.cpp \
    main.cpp

# Include target-specific files.
ifeq ($(call is-board-platform-in-list,msm8937), true)
LOCAL_SRC_FILES += power-8937.c
endif

ifneq ($(TARGET_POWER_SET_FEATURE_LIB),)
    LOCAL_STATIC_LIBRARIES += $(TARGET_POWER_SET_FEATURE_LIB)
endif

ifeq ($(TARGET_USES_INTERACTION_BOOST),true)
	LOCAL_CFLAGS += -DINTERACTION_BOOST
endif

ifneq ($(TARGET_POWERHAL_SET_INTERACTIVE_EXT),)
LOCAL_CFLAGS += -DSET_INTERACTIVE_EXT
LOCAL_SRC_FILES += ../../../$(TARGET_POWERHAL_SET_INTERACTIVE_EXT)
endif

ifneq ($(TARGET_TAP_TO_WAKE_NODE),)
    LOCAL_CFLAGS += -DTAP_TO_WAKE_NODE=\"$(TARGET_TAP_TO_WAKE_NODE)\"
endif

ifneq ($(TARGET_RPM_STAT),)
    LOCAL_CFLAGS += -DRPM_STAT=\"$(TARGET_RPM_STAT)\"
endif

ifneq ($(TARGET_RPM_MASTER_STAT),)
    LOCAL_CFLAGS += -DRPM_MASTER_STAT=\"$(TARGET_RPM_MASTER_STAT)\"
endif

ifneq ($(TARGET_RPM_SYSTEM_STAT),)
    LOCAL_CFLAGS += -DRPM_SYSTEM_STAT=\"$(TARGET_RPM_SYSTEM_STAT)\"
endif

LOCAL_MODULE := android.hardware.power-service.custom
LOCAL_INIT_RC := android.hardware.power-service.custom.rc
LOCAL_SHARED_LIBRARIES += android.hardware.power@1.1
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := qcom
LOCAL_VENDOR_MODULE := true
LOCAL_MODULE_TAGS := optional
LOCAL_CFLAGS += -Wno-unused-parameter -Wno-unused-variable
LOCAL_VINTF_FRAGMENTS := power.xml
LOCAL_HEADER_LIBRARIES := libhardware_headers
include $(BUILD_EXECUTABLE)

endif

endif
