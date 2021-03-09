/*
   Copyright (c) 2016, The CyanogenMod Project
   Copyright (c) 2019, The LineageOS Project

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <cstdlib>
#include <fstream>
#include <string.h>
#include <sys/sysinfo.h>
#include <unistd.h>

#include <android-base/properties.h>
#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

#include "vendor_init.h"
#include "property_service.h"

using android::base::GetProperty;
int property_set(const char *key, const char *value) {
	    return __system_property_set(key, value);
}

void property_override(char const prop[], char const value[])
{
    prop_info *pi;

    pi = (prop_info*) __system_property_find(prop);
    if (pi)
        __system_property_update(pi, value, strlen(value));
    else
        __system_property_add(prop, strlen(prop), value, strlen(value));
}

static bool is3GBram() {
    struct sysinfo sys;
    sysinfo(&sys);
    return sys.totalram > 2048ull * 1024 * 1024;
}

void init_target_properties()
{
    std::ifstream fin;
    std::string buf;
    fin.open("/proc/cmdline");
    while (std::getline(fin, buf, ' '))
      if (buf.find("board_id") != std::string::npos)
          break;
    fin.close();

    if (buf.find("S88505") != std::string::npos) {
        property_override("ro.product.model", "Redmi 5A");
	property_override("ro.product.device", "riva");
	property_override("ro.product.vendor.device", "riva");
        property_override("ro.vendor.build.fingerprint", "Xiaomi/riva/riva:7.1.2/N2G47H/V9.5.6.0.NCKMIFA:user/release-keys");
	// Specify LED Color is White Only
	property_override("ro.led.white_led", "1");
    }
}

static void set_ramconfig() {
    if (is3GBram()) {
        property_override("dalvik.vm.heapstartsize", "8m");
        property_override("dalvik.vm.heapgrowthlimit", "288m");
        property_override("dalvik.vm.heapsize", "768m");
        property_override("dalvik.vm.heaptargetutilization", "0.75");
        property_override("dalvik.vm.heapminfree", "512k");
        property_override("dalvik.vm.heapmaxfree", "8m");
    } else {
        property_override("dalvik.vm.heapstartsize", "8m");
        property_override("dalvik.vm.heapgrowthlimit", "192m");
        property_override("dalvik.vm.heapsize", "512m");
        property_override("dalvik.vm.heaptargetutilization", "0.75");
        property_override("dalvik.vm.heapminfree", "2m");
        property_override("dalvik.vm.heapmaxfree", "8m");
	// Reduce memory footprint
	property_override("ro.config.avoid_gfx_accel", "true");
    }
}

void vendor_load_properties()
{
    init_target_properties();
    set_ramconfig();
}
