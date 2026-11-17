// SPDX-License-Identifier: 0BSD
// LIGAZE: five named scenario ligands held by the native PENTAGONAL-COR.
// This is a transparent 30-bit comparison view, NOT a cryptographic signature.
#ifndef SWE_PENTAGONAL_LIGAZE_HPP
#define SWE_PENTAGONAL_LIGAZE_HPP

#include "pentagonal_gates.hpp"
#include <array>
#include <cstdint>
#include <string_view>

namespace swe::ligaze {
inline constexpr std::array<std::string_view,5> paths={
    "YIN", "YAN", "ZING", "YING", "YANG"
};
inline constexpr std::uint8_t five_mask=31u;
// Bit 1/3 are zero because YAN/YING throw intentionally.
// These are observed runtime outcomes, not qualification results.
inline constexpr std::uint8_t intended_outcomes=0b10101u;
inline constexpr std::uint8_t intended_conformance=0b11111u;

// Five bits are carried in each of six COR-compatible blocks:
//  0 = observed raw runtime outcomes
//  1 = intended raw runtime outcomes
//  2 = observed test conformance
//  3 = expected test conformance
//  4 = observed outcome passed through PENTAGONAL-NOP
//  5 = intended outcome passed through PENTAGONAL-NOP
// Six blocks are repeated VIEWS of the same 5 paths, not independent
// measurements or evidence. Mismatch flags 0..5 remain meaningful.
constexpr std::uint8_t preserve_nop(std::uint8_t input) noexcept {
    std::uint8_t output=0;
    for(unsigned i=0;i<5;++i) {
        const bool original=((input>>i)&1u)!=0;
        if(swe::pentagonal::pentagonal_nop(original))
            output=static_cast<std::uint8_t>(output|(1u<<i));
    }
    return output;
}
constexpr std::uint32_t blocks(std::uint8_t outcomes,
                                std::uint8_t expected,
                                std::uint8_t conformance,
                                std::uint8_t expected_conformance) noexcept {
    const std::uint32_t v0=outcomes&five_mask;
    const std::uint32_t v1=expected&five_mask;
    const std::uint32_t v2=conformance&five_mask;
    const std::uint32_t v3=expected_conformance&five_mask;
    const std::uint32_t v4=preserve_nop(outcomes)&five_mask;
    const std::uint32_t v5=preserve_nop(expected)&five_mask;
    return v0|(v1<<5u)|(v2<<10u)|(v3<<15u)|(v4<<20u)|(v5<<25u);
}
struct Held {
    std::uint8_t observed_outcomes{},expected_outcomes{};
    std::uint8_t observed_conformance{},expected_conformance{};
    swe::pentagonal::Vista witness{};
    bool matches_expected_behavior{}, all_checks_conformed{};
    bool source_mutated{};
    bool externally_authenticated{};
};
// The expected argument is an externally supplied reference, but not an
// independently authenticated witness: no signature or root of trust.
inline Held hold(std::uint8_t outcomes,std::uint8_t expected,
                 std::uint8_t conformance,
                 std::uint8_t expected_conformance) noexcept {
    outcomes&=five_mask; expected&=five_mask;
    conformance&=five_mask; expected_conformance&=five_mask;
    const auto observed_vector=blocks(outcomes,expected,conformance,expected_conformance);
    const auto expected_vector=blocks(expected,expected,expected_conformance,expected_conformance);
    const auto cor=swe::pentagonal::pentagonal_cor(
        observed_vector,expected_vector,swe::pentagonal::Entry::or_gate,
        true,true,true);
    return {outcomes,expected,conformance,expected_conformance,cor,
            outcomes==expected && cor.rupture==0,
            conformance==five_mask && conformance==expected_conformance,
            false,false};
}
constexpr bool raw_outcomes_semantically_valid(std::uint8_t input) noexcept {
    return (input&~five_mask)==0u;
}
static_assert(preserve_nop(intended_outcomes)==intended_outcomes);
static_assert(swe::pentagonal::boolean_gates(intended_outcomes).xor_value);
static_assert(!swe::pentagonal::boolean_gates(intended_outcomes).and_value);
static_assert(swe::pentagonal::boolean_gates(intended_conformance).and_value);
static_assert((blocks(intended_outcomes,intended_outcomes,
                      intended_conformance,intended_conformance)
             & five_mask)==intended_outcomes);
} // namespace swe::ligaze
#endif
