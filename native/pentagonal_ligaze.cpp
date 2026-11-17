// SPDX-License-Identifier: 0BSD
// Native C++20 LIGAZE binary, independently compiled from the Java JAR.
#include "pentagonal_ligaze.hpp"
#include <array>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>

namespace {
unsigned readFive(const char* raw) {
    const std::string str(raw);
    std::size_t end=0;
    const unsigned long value=std::stoul(str,&end,0);
    if(end!=str.size() || value>31u)
        throw std::invalid_argument("LIGAZE requires one integer 0..31 (0x00..0x1f) per field");
    return static_cast<unsigned>(value);
}
void printHex(std::uint64_t value, unsigned digits) {
    std::cout<<"0x"<<std::hex<<std::setw(static_cast<int>(digits))
             <<std::setfill('0')<<value<<std::dec<<std::setfill(' ');
}
}
int main(int argc,char** argv) {
    using namespace swe::ligaze;
    try {
        if(argc==2 && std::string_view(argv[1])=="--help") {
            std::cout<<"Usage: pentagonal_ligaze observed_outcomes intended_outcomes "
                        "observed_conformance expected_conformance\n"
                        "All four arguments are five-bit masks (0x00..0x1f).\n"
                        "LIGAZE order is YIN,YAN,ZING,YING,YANG as bits 0..4.\n"
                        "Intended raw result 0x15 means the negative YAN/YING cases throw.\n"
                        "Conformance 0x1f means all five behaviors matched their requirements.\n";
            return 0;
        }
        if(argc!=5) throw std::invalid_argument("Exactly four five-bit operands required; use --help");
        const auto actual=static_cast<std::uint8_t>(readFive(argv[1]));
        const auto intended=static_cast<std::uint8_t>(readFive(argv[2]));
        const auto checks=static_cast<std::uint8_t>(readFive(argv[3]));
        const auto required=static_cast<std::uint8_t>(readFive(argv[4]));
        const auto held=hold(actual,intended,checks,required);
        const bool qualified=held.matches_expected_behavior &&
                             held.all_checks_conformed &&
                             intended==intended_outcomes &&
                             required==intended_conformance;
        std::cout<<"{\"schema\":\"SWE-LIGAZE-COR-native-v1\","
                 <<"\"binary_kind\":\"native-cxx20\","
                 <<"\"source_mutated\":false,"
                 <<"\"externally_authenticated\":false,"
                 <<"\"five_ligands\":[\"YIN\",\"YAN\",\"ZING\",\"YING\",\"YANG\"],"
                 <<"\"observed_outcomes\":\"";
        printHex(actual,2);std::cout<<'"';
        std::cout<<",\"expected_outcomes\":\"";
        printHex(intended,2);std::cout<<'"';
        std::cout<<",\"observed_conformance\":\"";
        printHex(checks,2);std::cout<<'"';
        std::cout<<",\"required_conformance\":\"";
        printHex(required,2);std::cout<<'"';
        std::cout<<",\"nop_held_outcomes\":\"";
        printHex(preserve_nop(actual),2);std::cout<<'"';
        std::cout<<",\"cor_register\":";
        std::cout<<'"';printHex(held.witness.operand,16);std::cout<<'"';
        std::cout<<",\"cor_rupture_flags\":"<<held.witness.rupture
                 <<",\"cor_logical_evaluations\":"<<held.witness.evaluations
                 <<",\"raw_parity_xor\":"
                 <<(swe::pentagonal::boolean_gates(actual).xor_value?"true":"false")
                 <<",\"raw_any_or\":"
                 <<(swe::pentagonal::boolean_gates(actual).or_value?"true":"false")
                 <<",\"raw_all_and\":"
                 <<(swe::pentagonal::boolean_gates(actual).and_value?"true":"false")
                 <<",\"conformance_all_and\":"
                 <<(swe::pentagonal::boolean_gates(checks).and_value?"true":"false")
                 <<",\"matches_expected_behavior\":"
                 <<(held.matches_expected_behavior?"true":"false")
                 <<",\"all_checks_conformed\":"
                 <<(held.all_checks_conformed?"true":"false")
                 <<",\"qualification\":\""<<(qualified?"PASS":"FAIL")<<"\"}\n";
        // A mismatch is emitted as evidence, not fatal transport or mutation.
        return 0;
    } catch(const std::exception& e) {
        std::cerr<<"LIGAZE_INPUT_ERROR: "<<e.what()<<"\n";
        return 2;
    }
}
