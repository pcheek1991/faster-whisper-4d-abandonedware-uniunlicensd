// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
// A native UTF-8 preserving language registry. Nothing translates automatically.
#pragma once
#include <cstddef>
#include <cstdint>
#include <ostream>
#include <stdexcept>
#include <string>
#include <string_view>

namespace swe::word_bridges {
struct Language {
    std::string_view code;
    std::string_view english;
    std::string_view autonym;
    std::string_view wikipedia;
};
inline constexpr Language languages[] = {
#include "wikimedia_languages.inc"
};
inline constexpr std::size_t language_count = sizeof(languages) / sizeof(languages[0]);
static_assert(language_count == 348, "The pinned Wikimedia language inventory changed unexpectedly");

inline std::string code_key(std::string_view raw) {
    if (raw.empty() || raw.size() > 32u) return {};
    std::string result;
    for (const unsigned char ch : raw) {
        if (ch >= 'A' && ch <= 'Z') result.push_back(static_cast<char>(ch + ('a'-'A')));
        else if (ch == '_') result.push_back('-');
        else if ((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '-')
            result.push_back(static_cast<char>(ch));
        else return {};
    }
    return result;
}

inline const Language* find(std::string_view language_code) {
    const std::string key = code_key(language_code);
    if (key.empty()) return nullptr;
    for (const auto& language : languages)
        if (language.code == key) return &language;
    return nullptr;
}

// Strict Unicode scalar decoding, no normalization, reordering or substitutions.
inline bool valid_utf8(std::string_view s) noexcept {
    for (std::size_t i = 0; i < s.size();) {
        const auto b = static_cast<unsigned char>(s[i]);
        if (b < 0x80) { ++i; continue; }
        unsigned need = 0;
        std::uint32_t cp = 0, smallest = 0;
        if ((b & 0xe0u) == 0xc0u) { need = 1; cp = b & 0x1fu; smallest = 0x80u; }
        else if ((b & 0xf0u) == 0xe0u) { need = 2; cp = b & 0x0fu; smallest = 0x800u; }
        else if ((b & 0xf8u) == 0xf0u) { need = 3; cp = b & 0x07u; smallest = 0x10000u; }
        else return false;
        if (need > s.size() - i - 1u) return false;
        for (unsigned n = 1; n <= need; ++n) {
            const auto continuation = static_cast<unsigned char>(s[i + n]);
            if ((continuation & 0xc0u) != 0x80u) return false;
            cp = (cp << 6u) | (continuation & 0x3fu);
        }
        if (cp < smallest || cp > 0x10ffffu || (cp >= 0xd800u && cp <= 0xdfffu))
            return false;
        i += need + 1u;
    }
    return true;
}

inline void json_string(std::ostream& out, std::string_view str) {
    if (!valid_utf8(str)) throw std::invalid_argument("Invalid UTF-8 scalar sequence");
    constexpr char hex[] = "0123456789abcdef";
    out << '"';
    for (const unsigned char ch : str) {
        if (ch == '"' || ch == '\\') { out << '\\' << static_cast<char>(ch); }
        else if (ch < 0x20u) {
            out << "\\u00" << hex[ch >> 4u] << hex[ch & 15u];
        } else out << static_cast<char>(ch);
    }
    out << '"';
}

inline void list_languages(std::ostream& out) {
    for (const auto& l : languages) {
        out << l.code << '\t' << l.english << '\t' << l.autonym
            << '\t' << l.wikipedia << '\n';
    }
}
} // namespace swe::word_bridges
