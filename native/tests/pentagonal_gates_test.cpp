// SPDX-License-Identifier: 0BSD
#include "../pentagonal_gates.hpp"
#include <array>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <limits>

using namespace swe::pentagonal;
int main() {
    // Five Boolean ligands: exhaustive independent parity/OR/AND oracles.
    for (unsigned mask=0; mask<32; ++mask) {
        unsigned ones=0;
        std::array<double,5> values{};
        for (unsigned i=0; i<5; ++i) {
            const bool bit=(mask & (1u<<i))!=0;
            ones+=bit ? 1u : 0u;
            values[i]=bit ? 1.0 : 0.0;
        }
        const Gates actual=boolean_gates(static_cast<std::uint8_t>(mask));
        if (actual.xor_value != ((ones % 2u)!=0u) ||
            actual.or_value != (ones>0u) ||
            actual.and_value != (ones==5u)) return 1;
        PentagonalScores canonical{};
        if (!pentagonal_scores(values,canonical) ||
            canonical.xor_score != static_cast<double>(actual.xor_value) ||
            canonical.or_score != static_cast<double>(actual.or_value) ||
            canonical.and_score != static_cast<double>(actual.and_value)) return 2;
    }
    // Source rejects invalid continuous measurements without mutation.
    PentagonalScores unchanged{};
    unchanged.or_score=0.125;
    if (pentagonal_scores({0,1,0,std::numeric_limits<double>::quiet_NaN(),0},
                          unchanged) || unchanged.or_score!=0.125) return 3;
    if (pentagonal_scores({0,0,0,-0.1,0},unchanged) ||
        unchanged.or_score!=0.125) return 4;
    if (!pentagonal_nop(true) || pentagonal_nop(false)) return 5;

    const std::uint32_t baseline=ligand_mask;
    for (Entry entry : {Entry::or_gate,Entry::xor_gate,Entry::and_gate,Entry::fault}) {
        const Vista v=pentagonal_cor(baseline,baseline,entry);
        const unsigned count=entry==Entry::or_gate?96:
                             entry==Entry::xor_gate?64:
                             entry==Entry::and_gate?32:0;
        if (v.evaluations!=count ||
            evaluations_of(v.operand)!=count ||
            entry_of(v.operand)!=entry ||
            ligands_of(v.operand)!=baseline ||
            ruptures_of(v.operand)!=v.rupture) return 6;
        if (entry!=Entry::fault && (v.rupture!=0 || !v.valid_entry)) return 7;
        if (entry==Entry::fault && !(v.rupture & invalid_entry)) return 8;
    }
    for (unsigned block=0; block<6; ++block) {
        const unsigned bit=5u*block+2u;
        const std::uint32_t altered=baseline & ~(1u<<bit);
        const auto original=altered;
        const Vista v=pentagonal_cor(altered,baseline);
        if (v.rupture!=(1u<<block) || altered!=original ||
            v.blocks[block].and_value || !v.blocks[block].or_value ||
            v.blocks[block].xor_value) return 9;
        const Vista copied=pentagonal_vista(v);
        if (copied.operand!=v.operand || copied.observed!=altered ||
            copied.expected!=baseline) return 10;
    }
    const Vista alerts=pentagonal_cor(baseline,baseline,Entry::or_gate,
                                     false,false,false);
    if ((alerts.rupture & (missing_witness|replay_sequence|clock_regression)) !=
        (missing_witness|replay_sequence|clock_regression)) return 11;

    Machine m{};
    const Stage expected[]={
        Stage::xor_gate,Stage::or_gate,Stage::and_gate,
        Stage::nop,Stage::cor,Stage::flop
    };
    bool prior=false;
    for (unsigned i=0;i<6;++i) {
        const Step s=m.tick(baseline,baseline);
        if (s.stage!=expected[i]) return 12;
        if (i==2) prior=s.output;
        if (i==3 && s.output!=prior) return 13;
        if (i==4 && (s.vista.evaluations!=96 || s.vista.rupture!=0)) return 14;
        if (i<5 && s.loops_completed!=0) return 15;
        if (i==5 && s.loops_completed!=1) return 16;
    }
    // FLOP redirects to the existing entry; it doesn't execute another XOR.
    if (m.next!=Stage::xor_gate || m.loops!=1) return 17;
    if (m.tick(baseline,baseline).stage!=Stage::xor_gate) return 18;
    std::cout<<"PASS: 32 truth states, 6 blocks, 3 entry gates + fault, "
                "independent witness alerts, NOP, VISTA and exact six-stage FLOP\n";
    return 0;
}
