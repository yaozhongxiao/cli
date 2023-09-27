//
// Copyright 2021 WorkGroup Participants. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef TOOLS_GN_EXAMPLE_LIB_SHARED_H_
#define TOOLS_GN_EXAMPLE_LIB_SHARED_H_

#if defined(WIN32)

#if defined(LIB_SHARED_IMPLEMENTATION)
#define LIB_EXPORT __declspec(dllexport)
#define LIB_EXPORT_PRIVATE __declspec(dllexport)
#else
#define LIB_EXPORT __declspec(dllimport)
#define LIB_EXPORT_PRIVATE __declspec(dllimport)
#endif  // defined(LIB_SHARED_IMPLEMENTATION)

#else

#if defined(LIB_SHARED_IMPLEMENTATION)
#define LIB_EXPORT __attribute__((visibility("default")))
#define LIB_EXPORT_PRIVATE __attribute__((visibility("default")))
#else
#define LIB_EXPORT
#define LIB_EXPORT_PRIVATE
#endif  // defined(LIB_SHARED_IMPLEMENTATION)

#endif

LIB_EXPORT const char* GetSharedText();

#endif  // TOOLS_GN_EXAMPLE_LIB_SHARED_H_
