// SPDX-License-Identifier: 0BSD
// Windows v2 compile-time contract test. REAL Win32 APIs must not be replaced.
// This target is expected to REJECT the user's full variadic no-op header.
#if defined(SWE_LIGAZE_WINDOWS_FULL_HEADER_V2_EXPERIMENT)
#  include "../../native/benchmarks/windows_ligaze_user_header_v2_experiment.hpp"
#elif defined(SWE_LIGAZE_WINDOWS_FULL_HEADER_EXPERIMENT)
#  include "../../native/benchmarks/windows_ligaze_user_header_experiment.hpp"
#else
#  include "../pentagonal_platform_windows_v2.hpp"
#endif
#include <type_traits>

static_assert(swe::ligaze::platform_v2::architecture_name()!=nullptr);
#if defined(_WIN32)
static_assert(swe::ligaze::platform_v2::windows);
using Win32FileFn=HANDLE (WINAPI*)(LPCWSTR,DWORD,DWORD,LPSECURITY_ATTRIBUTES,DWORD,DWORD,HANDLE);
static_assert(requires { static_cast<Win32FileFn>(&::CreateFileW); },
    "Typed Win32 CreateFileW API must remain available");
template<typename T>
concept ForgedSleepCall = requires(T value) { ::Sleep(value,value); };
template<typename T>
concept ForgedCreateFileCall = requires(T value) { ::CreateFileW(value); };
static_assert(!ForgedSleepCall<DWORD>,
    "UNSAFE: do-nothing variadic Sleep overload accepts arbitrary calls");
static_assert(!ForgedCreateFileCall<int>,
    "UNSAFE: do-nothing variadic CreateFileW overload accepts wrong arguments");
#else
static_assert(!swe::ligaze::platform_v2::windows);
#endif
int main() {return 0;}
