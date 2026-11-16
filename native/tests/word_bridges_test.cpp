// SPDX-License-Identifier: 0BSD
#include "word_bridges.hpp"
#include <cassert>
#include <sstream>
int main() {
    using namespace swe::word_bridges;
    static_assert(language_count == 348);
    for (std::size_t i = 0; i < language_count; ++i) {
        const auto& l = languages[i];
        assert(find(l.code) == &l);
        assert(valid_utf8(l.english));
        assert(valid_utf8(l.autonym));
        assert(valid_utf8(l.wikipedia));
        if (i > 0) assert(languages[i - 1].code != l.code);
    }
    assert(find(" EN ") == nullptr);
    assert(find("EN") != nullptr);
    assert(find("be_tarask") != nullptr);
    assert(find("fa") != nullptr);
    assert(find("he") != nullptr);
    assert(find("zh") != nullptr);
    assert(find("ja") != nullptr);
    assert(find("ko") != nullptr);
    assert(find("xx-not-a-wikipedia-edition") == nullptr);
    assert(!valid_utf8(std::string("\xc0\x80",2)));
    assert(!valid_utf8(std::string("\xed\xa0\x80",3)));
    assert(!valid_utf8(std::string("\xf4\x90\x80\x80",4)));
    assert(!valid_utf8(std::string("\xe2\x82",2)));
    assert(valid_utf8("ქართული 中文 فارسی עברית 한국어 日本語"));
    std::stringstream out;
    json_string(out, "你好 \"World\" \n");
    assert(out.str().find("\\\"World\\\"") != std::string::npos);
    std::stringstream catalog;
    list_languages(catalog);
    unsigned count = 0;
    for (char c : catalog.str()) if (c == '\n') ++count;
    assert(count == language_count);
    return 0;
}
