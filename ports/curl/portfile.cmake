set(VERSION 7.77.0)
string(REPLACE "." "_" TAG ${VERSION})

# Get archive
vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/curl/curl/releases/download/curl-${TAG}/curl-${VERSION}.zip"
    FILENAME "curl-${VERSION}.zip"
    SHA512 52f0a0553c032fa0e77f25cf36760eb0615557066e539e7b6168e720d988e5a1ae1d0fde7c2f6bc51dc4808d2a8d820ffbeef6f3482cec95f758bc42b742cf85
)

# Patches
set(PATCHES
    ${CMAKE_CURRENT_LIST_DIR}/patches/0001-Adjust-CMake-for-vcpkg.patch
)

# Extract archive
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION}
    PATCHES ${PATCHES}
)

# Run CMake build
set(BUILD_OPTIONS
    # BUILD options
    -DBUILD_CURL_EXE=OFF
    -DBUILD_TESTING=OFF
    # CMAKE options
    -DCMAKE_USE_GSSAPI=OFF
    -DCMAKE_USE_LIBSSH2=OFF
    -DCMAKE_USE_OPENLDAP=OFF
    # CURL options
    -DCURL_BROTLI=ON
    -DCURL_ZLIB=ON
    -DCURL_DISABLE_ALTSVC=OFF
    -DCURL_DISABLE_COOKIES=ON
    -DCURL_DISABLE_CRYPTO_AUTH=OFF
    -DCURL_DISABLE_DICT=ON
    -DCURL_DISABLE_DOH=ON
    -DCURL_DISABLE_FILE=OFF
    -DCURL_DISABLE_FTP=ON
    -DCURL_DISABLE_GOPHER=ON
    -DCURL_DISABLE_HSTS=OFF
    -DCURL_DISABLE_HTTP=OFF
    -DCURL_DISABLE_IMAP=ON
    -DCURL_DISABLE_LDAP=ON
    -DCURL_DISABLE_LDAPS=ON
    -DCURL_DISABLE_MQTT=ON
    -DCURL_DISABLE_POP3=ON
    -DCURL_DISABLE_PROXY=OFF
    -DCURL_DISABLE_RTSP=ON
    -DCURL_DISABLE_SMB=ON
    -DCURL_DISABLE_SMTP=ON
    -DCURL_DISABLE_TELNET=ON
    -DCURL_DISABLE_TFTP=ON
    # ENABLE options
    -DENABLE_MANUAL=OFF
    -DENABLE_UNIX_SOCKETS=OFF
    # USE options
    -DUSE_NGHTTP2=ON
    -DUSE_WIN32_LDAP=OFF
)

# Check for ares feature
if (ares IN_LIST FEATURES)
    message(STATUS "Enabling c-ares")
    list(APPEND BUILD_OPTIONS -DENABLE_ARES=ON -DENABLE_THREADED_RESOLVER=OFF)
else ()
    list(APPEND BUILD_OPTIONS -DENABLE_ARES=OFF -DENABLE_THREADED_RESOLVER=ON)
endif ()

# Check for ca-bundle feature
if (ca-bundle IN_LIST FEATURES)
    message(STATUS "Enabling CA bundle")
    list(APPEND BUILD_OPTIONS -DCURL_CA_BUNDLE=auto -DCURL_CA_PATH=auto)
else ()
    message(STATUS "Disabling CA bundle")
    list(APPEND BUILD_OPTIONS -DCURL_CA_BUNDLE=none -DCURL_CA_PATH=none)
endif ()

# Check for IPV6 feature
if (ipv6 IN_LIST FEATURES)
    message(STATUS "Enabling IPV6")
    list(APPEND BUILD_OPTIONS -DENABLE_IPV6=ON)
else ()
    list(APPEND BUILD_OPTIONS -DENABLE_IPV6=OFF)
endif ()

if (NOT VCPKG_CMAKE_SYSTEM_NAME OR VCPKG_CMAKE_SYSTEM_NAME MATCHES "^Windows")
    set(VCPKG_WINDOWS ON)

    # Windows specific features
    list(APPEND BUILD_OPTIONS
        -DENABLE_INET_PTON=ON
        -DENABLE_UNICODE=ON
    )
endif ()

string(COMPARE EQUAL ${VCPKG_LIBRARY_LINKAGE} static CURL_STATICLIB)
if (VCPKG_WINDOWS)
    list(APPEND BUILD_OPTIONS -DCURL_STATIC_CRT=${CURL_STATICLIB})
endif ()

set(USE_OPENSSL ON)
if (NOT ssl IN_LIST FEATURES)
    message(STATUS "Using system SSL library")

    if (VCPKG_WINDOWS)
        set(USE_OPENSSL OFF)
        set(USE_SCHANNEL ON)
    endif ()
endif ()

if (NOT VCPKG_WINDOWS OR VCPKG_TARGET_ARCHITECTURE MATCHES "^arm")
    message(STATUS "Cross compiling curl")

    # When cross compiling curl it does not have the ability to use CMake's try_run
    # functionality so these values need to be set properly for the platform
    if (DEFINED CURL_CROSS_BUILD_OPTIONS)
        list(APPEND BUILD_OPTIONS ${CURL_CROSS_BUILD_OPTIONS})
    else ()
        message(FATAL_ERROR "CURL_CROSS_BUILD_OPTIONS needs to be set in the triplet file when cross compiling to communicate values determined by try_run")
    endif ()
endif ()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS 
        ${BUILD_OPTIONS}
        -DCURL_STATICLIB=${CURL_STATICLIB}
        -DCMAKE_USE_OPENSSL=${USE_OPENSSL}
        -DCMAKE_USE_SCHANNEL=${USE_SCHANNEL}
    OPTIONS_DEBUG
        -DENABLE_DEBUG=ON
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

# Prepare distribution
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/curl RENAME copyright)
file(WRITE ${CURRENT_PACKAGES_DIR}/share/curl/version ${VERSION})
