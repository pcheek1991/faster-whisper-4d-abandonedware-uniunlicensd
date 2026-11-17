// SPDX-License-Identifier: 0BSD
// Exact pure-native truth table and COR 30-bit binding validation.
#include "../pentagonal_ligaze.hpp"
#include <cstdint>
#include <iostream>

using namespace swe::ligaze;
int main() {
    const Held baseline=hold(intended_outcomes,intended_outcomes,
                             intended_conformance,intended_conformance);
    if(baseline.witness.rupture!=0 || baseline.witness.evaluations!=96 ||
       !baseline.matches_expected_behavior || !baseline.all_checks_conformed ||
       baseline.externally_authenticated || baseline.source_mutated) return 1;
    if(swe::pentagonal::boolean_gates(intended_outcomes).and_value ||
       !swe::pentagonal::boolean_gates(intended_outcomes).xor_value ||
       !swe::pentagonal::boolean_gates(intended_conformance).and_value) return 2;
    for(unsigned bit=0;bit<5;++bit) {
        const auto outcome=static_cast<std::uint8_t>(intended_outcomes^(1u<<bit));
        const Held changed=hold(outcome,intended_outcomes,
                                intended_conformance,intended_conformance);
        if(changed.witness.rupture!=0x11u || changed.matches_expected_behavior ||
           changed.witness.observed!=blocks(outcome,intended_outcomes,
                                  intended_conformance,intended_conformance)) return 3;
        const auto conformance=static_cast<std::uint8_t>(intended_conformance^(1u<<bit));
        const Held checkBroken=hold(intended_outcomes,intended_outcomes,
                                   conformance,intended_conformance);
        if(checkBroken.witness.rupture!=0x04u || checkBroken.all_checks_conformed)
            return 4;
    }
    unsigned cases=0;
    for(unsigned observed=0; observed<32; ++observed)
    for(unsigned expected=0; expected<32; ++expected) {
        const auto o=static_cast<std::uint8_t>(observed);
        const auto e=static_cast<std::uint8_t>(expected);
        const Held check=hold(o,e,intended_conformance,intended_conformance);
        const unsigned mismatch=observed==expected?0u:0x11u;
        if(check.witness.rupture!=mismatch ||
           check.matches_expected_behavior!=(observed==expected) ||
           preserve_nop(o)!=o) return 5;
        ++cases;
    }
    for(unsigned observed=0;observed<32;++observed)
    for(unsigned expected=0;expected<32;++expected) {
        const auto o=static_cast<std::uint8_t>(observed);
        const auto e=static_cast<std::uint8_t>(expected);
        const Held check=hold(intended_outcomes,intended_outcomes,o,e);
        const unsigned mismatch=observed==expected?0u:0x04u;
        if(check.witness.rupture!=mismatch ||
           check.all_checks_conformed!=(observed==31&&expected==31)) return 6;
        ++cases;
    }
    const auto invalid=hold(255u,255u,255u,255u);
    if(invalid.observed_outcomes!=31u || invalid.observed_conformance!=31u ||
       invalid.witness.rupture!=0u) return 7;
    std::cout<<"LIGAZE_NATIVE_TEST|PASS|cases="<<cases
             <<"|single_flip_injections=10|five_paths=5|cor_blocks=6"
             <<"|raw_expected=0x15|conformance_expected=0x1f"
             <<"|source_mutated=false|authenticated=false\n";
    return 0;
}
