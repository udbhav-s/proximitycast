project(MyProject)

cmake_minimum_required(VERSION 3.4.1)

add_library(
        gmp
        SHARED
        IMPORTED
        GLOBAL
)
set_target_properties(
        gmp
        PROPERTIES
        IMPORTED_LOCATION
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main/customJniLibs/${ANDROID_ABI}/libgmp.so
)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/customJniLibs/${ANDROID_ABI})

add_library(
        paillier
        SHARED
        ../../src/libpaillier-0.8/paillier.c
        ../../src/libpaillier-0.8/paillier.h
)
include_directories(../../src/libpaillier-0.8)

target_link_libraries(
        paillier
        gmp
)

add_library(
        UTM
        SHARED
        ../../src/UTM/UTM.cpp
        ../../src/UTM/UTM.h
)
include_directories(../../src/UTM)

add_library(
        mymain
        SHARED
        ../../src/coords.cpp
        ../../src/coords.h
        ../../src/crypto_functions.cpp
        ../../src/crypto_functions.h
)

target_link_libraries(
        mymain
        gmp
        paillier
        UTM
)

find_library( # Defines the name of the path variable that stores the
        # location of the NDK library.
        log-lib

        # Specifies the name of the NDK library that
        # CMake needs to locate.
        log )

# Links your native library against one or more other native libraries.
target_link_libraries( # Specifies the target library.
        mymain

        # Links the log library to the target library.
        ${log-lib} )