
set(CURLPP_VER 0.8.1)
include(vcpkg_common_functions)
set(SOURCE_PATH "${CURRENT_BUILDTREES_DIR}/src/curlpp-${CURLPP_VER}")

# I think this is a better option than getting the archive and exploding...
# However, I couldn't get it to work after an hour or so.
#vcpkg_from_github(
#    OUT_SOURCE_PATH SOURCE_PATH
#    REPO jpbarrette/curlpp
#    REF v0.8.1
#    SHA512???
#    HEAD_REF master
#)

vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/jpbarrette/curlpp/archive/v0.8.1.zip"
    FILENAME "curlpp-0.8.1.zip"
    SHA512 c668bb22c746544688dc8cdf3141696e585051d787589128fa9e49164985d75e2391a4ca63c62a188709e97b8ee24c7e5434ca8e7fce49cc08f2cb5923924526
)
vcpkg_extract_source_archive(${ARCHIVE})

# The original author of curlpp unconditionally sets CMAKE_INSTALL_PREFIX for windows builds,
# which makes this whole process fail at the very end.  This patch
# simply comments out that part of the curlpp CMakeLists.txt
# Note that generating the diff was an adventure because vcpkg changes
# the CMakeLists.txt before you have control...
# At the very least this should be documented.
vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt.patch"
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA # Disable this option if project cannot be built with Ninja
    # OPTIONS --trace
    OPTIONS -LA
    # OPTIONS -DUSE_THIS_IN_ALL_BUILDS=1 -DUSE_THIS_TOO=2
    # OPTIONS_RELEASE -DOPTIMIZE=1
    # OPTIONS_DEBUG -DDEBUGGABLE=1
)

vcpkg_install_cmake()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/doc/license DESTINATION ${CURRENT_PACKAGES_DIR}/share/curlpp RENAME copyright)

# Cleanup include files installed to the target install debug directory
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

