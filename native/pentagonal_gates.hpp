// SPDX-License-Identifier: 0BSD
// PENTAGONAL gates: native, explicitly experimental software controller.
// The original pentagonal_xor_std_free.h remains the score authority.
#ifndef SWE_PENTAGONAL_GATES_HPP
#define SWE_PENTAGONAL_GATES_HPP

#include "pentagonal_xor_std_free.h"
#include <array>
#include <cmath>
#include <cstdint>

namespace swe::pentagonal {

struct Gates {
    bool xor_value{}, or_value{}, and_value{};
};

// The Boolean specialization of the unchanged five-input parity kernel.
constexpr Gates boolean_gates(std::uint8_t mask) noexcept {
    mask = static_cast<std::uint8_t>(mask & 31u);
    bool odd = false;
    for (unsigned bit=0; bit<5; ++bit)
        odd = odd != ((mask & (1u << bit)) != 0u);
    return {odd, mask != 0u, mask == 31u};
}

// The original probabilistic source computes all three continuous scores.
// These are meaningful as probabilities only with appropriate input modeling.
inline bool pentagonal_scores(const std::array<double,5>& features,
                              PentagonalScores& out) noexcept {
    for (double x : features)
        if (!std::isfinite(x) || x < 0.0 || x > 1.0) return false;
    const Features5 f{features[0],features[1],features[2],
                      features[3],features[4]};
    out = swe_pxor_scores5(f);
    return true;
}
constexpr bool pentagonal_nop(bool previous) noexcept { return previous; }

enum class Entry : std::uint8_t { or_gate=0, xor_gate=1, and_gate=2, fault=3 };
enum class Stage : std::uint8_t {
    xor_gate=0, or_gate=1, and_gate=2, nop=3, cor=4, flop=5
};

inline constexpr std::uint32_t ligand_mask = 0x3fffffffu;
inline constexpr std::uint16_t missing_witness = 0x0100u;
inline constexpr std::uint16_t replay_sequence = 0x0200u;
inline constexpr std::uint16_t clock_regression = 0x0400u;
inline constexpr std::uint16_t invalid_entry = 0x8000u;

// Original proposed software operand:
// [63:62] entry, [61:32] six blocks of five ligands,
// [31:16] logical truth-table evaluations, [15:0] rupture flags.
// Logical evaluations are not microcontroller clock cycles.
constexpr std::uint64_t pack(Entry entry, std::uint32_t ligands,
                             std::uint16_t evaluations,
                             std::uint16_t ruptures) noexcept {
    return (static_cast<std::uint64_t>(entry) << 62u) |
           (static_cast<std::uint64_t>(ligands & ligand_mask) << 32u) |
           (static_cast<std::uint64_t>(evaluations) << 16u) |
           static_cast<std::uint64_t>(ruptures);
}
constexpr Entry entry_of(std::uint64_t v) noexcept {
    return static_cast<Entry>((v >> 62u) & 3u);
}
constexpr std::uint32_t ligands_of(std::uint64_t v) noexcept {
    return static_cast<std::uint32_t>((v >> 32u) & ligand_mask);
}
constexpr std::uint16_t evaluations_of(std::uint64_t v) noexcept {
    return static_cast<std::uint16_t>((v >> 16u) & 65535u);
}
constexpr std::uint16_t ruptures_of(std::uint64_t v) noexcept {
    return static_cast<std::uint16_t>(v & 65535u);
}

struct Vista {
    std::uint64_t operand{};
    std::uint32_t observed{}, expected{};
    std::uint16_t rupture{}, evaluations{};
    std::array<Gates,6> blocks{};
    Entry entry{Entry::or_gate};
    bool witness_present{}, valid_entry{};
};

// Forward-only, nonmutating telemetry. A local expected value is not
// independent authentication: the witness must be protected externally.
inline Vista pentagonal_cor(std::uint32_t observed, std::uint32_t expected,
                            Entry entry=Entry::or_gate,
                            bool witness_present=true,
                            bool sequence_fresh=true,
                            bool clock_nondecreasing=true) noexcept {
    Vista v{};
    v.observed = observed & ligand_mask;
    v.expected = expected & ligand_mask;
    v.entry = entry;
    v.witness_present = witness_present;
    v.valid_entry = entry != Entry::fault;
    if (!witness_present) v.rupture |= missing_witness;
    if (!sequence_fresh) v.rupture |= replay_sequence;
    if (!clock_nondecreasing) v.rupture |= clock_regression;
    if (!v.valid_entry) v.rupture |= invalid_entry;
    for (unsigned i=0; i<6; ++i) {
        const auto actual = static_cast<std::uint8_t>((v.observed >> (5u*i)) & 31u);
        const auto reference = static_cast<std::uint8_t>((v.expected >> (5u*i)) & 31u);
        v.blocks[i] = boolean_gates(actual);
        if (witness_present && actual != reference)
            v.rupture = static_cast<std::uint16_t>(v.rupture | (1u << i));
    }
    // COR retains its previously specified entry semantics: 32 logical
    // cases per stage, with OR, XOR, AND order and upstream bypass.
    if (v.valid_entry) {
        for (unsigned stage=static_cast<unsigned>(entry); stage<3; ++stage)
            for (unsigned mask=0; mask<32; ++mask) {
                const Gates g = boolean_gates(static_cast<std::uint8_t>(mask));
                const bool bit = stage==0 ? g.or_value :
                                 stage==1 ? g.xor_value : g.and_value;
                (void)bit; // audit states computed; no manufactured clock timing
                ++v.evaluations;
            }
    }
    v.operand = pack(entry,v.observed,v.evaluations,v.rupture);
    return v;
}

// PENTAGONAL-VISTA is a read-only snapshot, not an override of source bytes.
constexpr Vista pentagonal_vista(const Vista& witness) noexcept { return witness; }

struct Step {
    Stage stage{};
    bool output{};
    std::uint64_t loops_completed{};
    Vista vista{};
};

// Requested application sequence, distinct from COR's internal audit sweep:
// XOR -> OR -> AND -> NOP -> COR -> FLOP (return to entry).
// FLOP does NOT execute an extra XOR. Caller decides when tick occurs.
// No implicit spin loop, scheduler, or assertion about hardware sleep.
struct Machine {
    Stage next{Stage::xor_gate};
    bool held_value{};
    std::uint64_t loops{};
    Step tick(std::uint32_t observed, std::uint32_t expected,
              Entry entry=Entry::or_gate, bool witness_present=true,
              bool sequence_fresh=true,
              bool clock_nondecreasing=true) noexcept {
        Step s{};
        s.stage = next;
        const Gates g = boolean_gates(static_cast<std::uint8_t>(observed & 31u));
        switch (next) {
        case Stage::xor_gate: held_value=g.xor_value; next=Stage::or_gate; break;
        case Stage::or_gate: held_value=g.or_value; next=Stage::and_gate; break;
        case Stage::and_gate: held_value=g.and_value; next=Stage::nop; break;
        case Stage::nop: held_value=pentagonal_nop(held_value); next=Stage::cor; break;
        case Stage::cor:
            s.vista=pentagonal_cor(observed,expected,entry,witness_present,
                                   sequence_fresh,clock_nondecreasing);
            next=Stage::flop; break;
        case Stage::flop:
            ++loops;
            next=Stage::xor_gate; // branch to existing entry, no seventh stage
            break;
        }
        s.output=held_value;
        s.loops_completed=loops;
        return s;
    }
};
static_assert(boolean_gates(31).and_value);
static_assert(boolean_gates(7).xor_value);
static_assert(!boolean_gates(3).xor_value);
static_assert(pentagonal_nop(true));
static_assert(entry_of(pack(Entry::xor_gate,31,64,0))==Entry::xor_gate);
} // namespace swe::pentagonal
#endif // SWE_PENTAGONAL_GATES_HPP
