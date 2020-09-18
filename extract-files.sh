#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2019 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=rolex
VENDOR=xiaomi

# Load extractutils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}"/../../..

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in

    vendor/lib/libmmcamera2_sensor_modules.so)
        sed -i "s|/system/etc/camera|/vendor/etc/camera|g" "${2}"
        ;;

    vendor/lib/libmmcamera2_stats_modules.so)
        sed -i "s|libgui.so|libwui.so|g" "${2}"
        "${PATCHELF}" --replace-needed "libandroid.so" "libshim_android.so" "${2}"
        ;;

    vendor/lib/libmmsw_detail_enhancement.so|vendor/lib/libmmsw_platform.so|vendor/lib64/libmmsw_detail_enhancement.so|vendor/lib64/libmmsw_platform.so)
        sed -i "s|libgui.so|libwui.so|g" "${2}"
        ;;

    vendor/lib/libFaceGrade.so|vendor/lib/libarcsoft_beauty_shot.so)
        "${PATCHELF}" --remove-needed "libandroid.so" "${2}"
        ;;

    vendor/lib/libmmcamera2_stats_modules.so)
	"${PATCHELF}" --replace-needed "libandroid.so" "libcamera_shim.so" "${2}"
	;;

    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

extract "${MY_DIR}/proprietary-files-qc.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

DEVICE_BLOB_ROOT="$ANDROID_ROOT"/vendor/"${VENDOR}"/"${DEVICE}"/proprietary

# Camera data
for CAMERA_LIB in libmmcamera2_cpp_module.so libmmcamera2_dcrf.so libmmcamera2_iface_modules.so libmmcamera2_imglib_modules.so libmmcamera2_mct.so libmmcamera2_pproc_modules.so libmmcamera2_q3a_core.so libmmcamera2_sensor_modules.so libmmcamera2_stats_algorithm.so libmmcamera2_stats_modules.so libmmcamera_dbg.so libmmcamera_imglib.so libmmcamera_pdaf.so libmmcamera_pdafcamif.so libmmcamera_tintless_algo.so libmmcamera_tintless_bg_pca_algo.so libmmcamera_tuning.so; do
    sed -i "s|/data/misc/camera|/data/vendor/qcam|g" "${DEVICE_BLOB_ROOT}"/vendor/lib/${CAMERA_LIB}
done

for CAMERA_LIB64 in libmmcamera2_q3a_core.so libmmcamera2_stats_algorithm.so libmmcamera_dbg.so libmmcamera_tintless_algo.so libmmcamera_tintless_bg_pca_algo.so; do
    sed -i "s|/data/misc/camera|/data/vendor/qcam|g" "${DEVICE_BLOB_ROOT}"/vendor/lib64/${CAMERA_LIB64}
done

# Camera socket
sed -i "s|/data/misc/camera/cam_socket|/data/vendor/qcam/cam_socket|g" "$DEVICE_BLOB_ROOT"/vendor/bin/mm-qcamera-daemon

"${MY_DIR}/setup-makefiles.sh"
