// SPDX-License-Identifier: 0BSD
// Safe Windows architecture / include policy derived from experimental v2.
// No NOAPI flags, no OS function shadowing, no global macro undefinitions.
// Windows architecture detection is compile-time metadata, not runtime tuning.
#pragma once
#if defined(_WIN32) || defined(_WIN64)
#  define SWE_LIGAZE_PLATFORM_WINDOWS 1
#else
#  define SWE_LIGAZE_PLATFORM_WINDOWS 0
#endif
#if defined(__CYGWIN__)
#  define SWE_LIGAZE_PLATFORM_CYGWIN 1
#else
#  define SWE_LIGAZE_PLATFORM_CYGWIN 0
#endif
#if SWE_LIGAZE_PLATFORM_WINDOWS
#  ifndef STRICT
#    define STRICT
#  endif
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  ifndef NOMINMAX
#    define NOMINMAX
#  endif
#  include <windows.h>
#endif
namespace swe::ligaze::platform_v2 {
enum class Architecture : unsigned {
    unknown, x86, x64, arm32, arm64, arm64ec, ia64, mips, alpha, powerpc
};
inline constexpr bool windows=(SWE_LIGAZE_PLATFORM_WINDOWS!=0);
inline constexpr bool cygwin=(SWE_LIGAZE_PLATFORM_CYGWIN!=0);
#if defined(_M_ARM64EC)
inline constexpr Architecture architecture=Architecture::arm64ec;
#elif defined(_M_ARM64) || defined(__aarch64__) || defined(__arm64__)
inline constexpr Architecture architecture=Architecture::arm64;
#elif defined(_M_ARM) || defined(__arm__)
inline constexpr Architecture architecture=Architecture::arm32;
#elif defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__)
inline constexpr Architecture architecture=Architecture::x64;
#elif defined(_M_IX86) || defined(__i386__)
inline constexpr Architecture architecture=Architecture::x86;
#elif defined(_M_IA64) || defined(__ia64__)
inline constexpr Architecture architecture=Architecture::ia64;
#elif defined(_M_MRX000) || defined(__mips__)
inline constexpr Architecture architecture=Architecture::mips;
#elif defined(_M_ALPHA) || defined(__alpha__)
inline constexpr Architecture architecture=Architecture::alpha;
#elif defined(_M_PPC) || defined(__powerpc__)
inline constexpr Architecture architecture=Architecture::powerpc;
#else
inline constexpr Architecture architecture=Architecture::unknown;
#endif
// Architecture macro is an inspection of compilation target, NOT a run-time
// processor instruction feature test. No "fastest" CPU-path claim is made.
constexpr const char* architecture_name() noexcept {
    switch(architecture) {
      case Architecture::x86: return "x86";
      case Architecture::x64: return "x64";
      case Architecture::arm32: return "arm32";
      case Architecture::arm64: return "arm64";
      case Architecture::arm64ec: return "arm64ec";
      case Architecture::ia64: return "ia64";
      case Architecture::mips: return "mips";
      case Architecture::alpha: return "alpha";
      case Architecture::powerpc: return "powerpc";
      default: return "unknown";
    }
}
}
