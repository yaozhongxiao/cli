# Copyright 2023 WorkGroup Participants. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://github.com/openxla/iree/blob/main/build_tools/cmake/riscv.toolchain.cmake

cmake_minimum_required(VERSION 3.10)

if(RISCV_TOOLCHAIN_INCLUDED)
  return()
endif(RISCV_TOOLCHAIN_INCLUDED)
set(RISCV_TOOLCHAIN_INCLUDED true)

set(CMAKE_SYSTEM_PROCESSOR riscv)
set(RISCV_HOST_TAG linux)

if(NOT RISCV_HOME)
  message(FATAL_ERROR "please provide RISCV_HOME with cmake -DRISCV_HOME=path")
endif()

set(RISCV_TOOL_PATH "$ENV{RISCV_HOME}" CACHE PATH "RISC-V tool path")

set(RISCV_TOOLCHAIN_ROOT "${RISCV_TOOL_PATH}" CACHE PATH "RISC-V compiler path")
set(RISCV_TOOLCHAIN_PREFIX "riscv64-unknown-elf-" CACHE STRING "RISC-V toolchain prefix")
set(CMAKE_FIND_ROOT_PATH ${RISCV_TOOLCHAIN_ROOT})
list(APPEND CMAKE_PREFIX_PATH "${RISCV_TOOLCHAIN_ROOT}")

set(CMAKE_C_COMPILER "${RISCV_TOOLCHAIN_ROOT}/bin/clang")
set(CMAKE_CXX_COMPILER "${RISCV_TOOLCHAIN_ROOT}/bin/clang++")
set(CMAKE_AR "${RISCV_TOOLCHAIN_ROOT}/bin/llvm-ar")
set(CMAKE_RANLIB "${RISCV_TOOLCHAIN_ROOT}/bin/llvm-ranlib")
set(CMAKE_STRIP "${RISCV_TOOLCHAIN_ROOT}/bin/llvm-strip")

set(RISCV_COMPILER_FLAGS)
set(RISCV_COMPILER_FLAGS_CXX)
set(RISCV_COMPILER_FLAGS_DEBUG)
set(RISCV_COMPILER_FLAGS_RELEASE)
set(RISCV_LINKER_FLAGS)
set(RISCV_LINKER_FLAGS_EXE)

if (RISCV_CPU MATCHES "generic")
  set(CMAKE_SYSTEM_NAME Generic)
  set(CMAKE_SYSTEM_LIBRARY_PATH "${RISCV_TOOLCHAIN_ROOT}/lib/")
  set(CMAKE_CROSSCOMPILING ON CACHE BOOL "")
  set(CMAKE_C_STANDARD 11)
  set(CMAKE_C_EXTENSIONS OFF)     # Force the usage of _ISOC11_SOURCE
  set(IREE_BUILD_BINDINGS_TFLITE OFF CACHE BOOL "" FORCE)
  set(IREE_BUILD_BINDINGS_TFLITE_JAVA OFF CACHE BOOL "" FORCE)
  set(IREE_HAL_DRIVER_DEFAULTS OFF CACHE BOOL "" FORCE)
  set(IREE_HAL_DRIVER_LOCAL_SYNC ON CACHE BOOL "" FORCE)
  set(IREE_HAL_EXECUTABLE_LOADER_DEFAULTS OFF CACHE BOOL "" FORCE)
  set(IREE_HAL_EXECUTABLE_LOADER_EMBEDDED_ELF ON CACHE BOOL "" FORCE)
  set(IREE_HAL_EXECUTABLE_LOADER_VMVX_MODULE ON CACHE BOOL "" FORCE)
  set(IREE_HAL_EXECUTABLE_PLUGIN_DEFAULTS OFF CACHE BOOL "" FORCE)
  set(IREE_HAL_EXECUTABLE_PLUGIN_EMBEDDED_ELF ON CACHE BOOL "" FORCE)
  set(IREE_ENABLE_THREADING OFF CACHE BOOL "" FORCE)
elseif(RISCV_CPU MATCHES "linux")
  set(CMAKE_SYSTEM_NAME Linux)
endif()

if(RISCV_CPU MATCHES "riscv_64")
  set(CMAKE_SYSTEM_PROCESSOR riscv64)
elseif(RISCV_CPU MATCHES "riscv_32")
  set(CMAKE_SYSTEM_PROCESSOR riscv32)
endif()

if(RISCV_CPU STREQUAL "linux-riscv_64")
  set(CMAKE_SYSTEM_LIBRARY_PATH "${RISCV_TOOLCHAIN_ROOT}/sysroot/usr/lib")
  # Specify ISP spec for march=rv64gc. This is to resolve the mismatch between
  # llvm and binutil ISA version.
  set(RISCV_COMPILER_FLAGS "${RISCV_COMPILER_FLAGS} \
      -march=rv64i2p0ma2p0f2p0d2p0c2p0 -mabi=lp64d")
  set(RISCV_LINKER_FLAGS "${RISCV_LINKER_FLAGS} -lstdc++ -lpthread -lm -ldl")
  set(RISCV64_TEST_DEFAULT_LLVM_FLAGS
    "llvmcpu-target-triple=riscv64"
    "llvmcpu-target-cpu=generic-rv64"
    "llvmcpu-target-abi=lp64d"
    "llvmcpu-target-cpu-features=+m,+a,+f,+d,+c,+zvl512b,+v"
    "--riscv-v-fixed-length-vector-lmul-max=8"
    CACHE INTERNAL "Default llvm codegen flags for testing purposes")
elseif(RISCV_CPU STREQUAL "generic-riscv_64")
  # Specify ISP spec for march=rv64gc. This is to resolve the mismatch between
  # llvm and binutil ISA version.
  set(RISCV_COMPILER_FLAGS "${RISCV_COMPILER_FLAGS} \
      -march=rv64i2p0ma2p0f2p0d2p0c2p0 -mabi=lp64d -DIREE_PLATFORM_GENERIC=1 -DIREE_SYNCHRONIZATION_DISABLE_UNSAFE=1 \
      -DIREE_FILE_IO_ENABLE=0 -DIREE_TIME_NOW_FN=\"\{ return 0; \}\" -DIREE_DEVICE_SIZE_T=uint64_t -DPRIdsz=PRIu64")
  set(RISCV_LINKER_FLAGS "${RISCV_LINKER_FLAGS} -lm")
elseif(RISCV_CPU STREQUAL "linux-riscv_32")
  list(APPEND CMAKE_SYSTEM_LIBRARY_PATH
    "${RISCV_TOOLCHAIN_ROOT}/sysroot/usr/lib32"
    "${RISCV_TOOLCHAIN_ROOT}/sysroot/usr/lib32/ilp32d"
  )
  set(RISCV_COMPILER_FLAGS "${RISCV_COMPILER_FLAGS} \
      -march=rv32i2p0ma2p0f2p0d2p0c2p0 -mabi=ilp32d \
      -Wno-atomic-alignment")
  set(RISCV_LINKER_FLAGS "${RISCV_LINKER_FLAGS} -lstdc++ -lpthread -lm -ldl -latomic")
  set(RISCV32_TEST_DEFAULT_LLVM_FLAGS
    "--iree-llvmcpu-target-triple=riscv32"
    "--iree-llvmcpu-target-cpu=generic-rv32"
    "--iree-llvmcpu-target-abi=ilp32d"
    "--iree-llvmcpu-target-cpu-features=+m,+a,+f,+d,+zvl512b,+zve32f"
    "--riscv-v-fixed-length-vector-lmul-max=8"
    CACHE INTERNAL "Default llvm codegen flags for testing purposes")
elseif(RISCV_CPU STREQUAL "generic-riscv_32")
  # Specify ISP spec for march=rv32gc. This is to resolve the mismatch between
  # llvm and binutil ISA version.
  set(RISCV_COMPILER_FLAGS "${RISCV_COMPILER_FLAGS} \
      -march=rv32i2p0mf2p0 -mabi=ilp32 -DIREE_PLATFORM_GENERIC=1 -DIREE_SYNCHRONIZATION_DISABLE_UNSAFE=1 \
      -DIREE_FILE_IO_ENABLE=0 -DIREE_TIME_NOW_FN=\"\{ return 0; \}\" -DIREE_DEVICE_SIZE_T=uint32_t -DPRIdsz=PRIu32")
  set(RISCV_LINKER_FLAGS "${RISCV_LINKER_FLAGS} -lm")
endif()

set(CMAKE_C_FLAGS             "${RISCV_COMPILER_FLAGS} ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS           "${RISCV_COMPILER_FLAGS} ${RISCV_COMPILER_FLAGS_CXX} ${CMAKE_CXX_FLAGS}")
set(CMAKE_ASM_FLAGS           "${RISCV_COMPILER_FLAGS} ${CMAKE_ASM_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG       "${RISCV_COMPILER_FLAGS_DEBUG} ${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS_DEBUG     "${RISCV_COMPILER_FLAGS_DEBUG} ${CMAKE_CXX_FLAGS_DEBUG}")
set(CMAKE_ASM_FLAGS_DEBUG     "${RISCV_COMPILER_FLAGS_DEBUG} ${CMAKE_ASM_FLAGS_DEBUG}")
set(CMAKE_C_FLAGS_RELEASE     "${RISCV_COMPILER_FLAGS_RELEASE} ${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_RELEASE   "${RISCV_COMPILER_FLAGS_RELEASE} ${CMAKE_CXX_FLAGS_RELEASE}")
set(CMAKE_ASM_FLAGS_RELEASE   "${RISCV_COMPILER_FLAGS_RELEASE} ${CMAKE_ASM_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS "${RISCV_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS}")
set(CMAKE_MODULE_LINKER_FLAGS "${RISCV_LINKER_FLAGS} ${CMAKE_MODULE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS    "${RISCV_LINKER_FLAGS} ${RISCV_LINKER_FLAGS_EXE} ${CMAKE_EXE_LINKER_FLAGS}")
