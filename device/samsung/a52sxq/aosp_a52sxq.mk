#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Pixel stuff.
$(call inherit-product, vendor/aosp/config/common_full_phone.mk)

# Inherit from a52sxq device
$(call inherit-product, device/samsung/a52sxq/device.mk)

PRODUCT_DEVICE := a52sxq
PRODUCT_NAME := aosp_a52sxq
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-A528B
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung-ss

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="a52sxqxx-user 12 SP1A.210812.016 A528BXXU1CVG7 release-keys"

BUILD_FINGERPRINT := samsung/a52sxqxx/a52sxq:11/RP1A.200720.012/A528BXXU1CVG7:user/release-keys
