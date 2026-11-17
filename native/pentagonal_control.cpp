// SPDX-License-Identifier: 0BSD
// PENTAGONAL control: explicit six-stage machine and non-mutating VISTA.
#include "pentagonal_gates.hpp"
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>

namespace {
std::uint32_t parse30(std::string_view input) {
    const std::string s(input);
    std::size_t end=0;
    const unsigned long long n=std::stoull(s,&end,0);
    if (end!=s.size() || n>swe::pentagonal::ligand_mask)
        throw std::invalid_argument("Expected a 30-bit number (e.g. 0x3fffffff)");
    return static_cast<std::uint32_t>(n);
}
swe::pentagonal::Entry parse_entry(std::string_view s) {
    using E=swe::pentagonal::Entry;
    if(s=="or") return E::or_gate;
    if(s=="xor") return E::xor_gate;
    if(s=="and") return E::and_gate;
    if(s=="fault") return E::fault;
    throw std::invalid_argument("Entry must be or, xor, and, or fault");
}
}
int main(int argc,char** argv) {
    using namespace swe::pentagonal;
    try {
        if(argc>4) throw std::invalid_argument("Too many arguments");
        if(argc==2 && std::string_view(argv[1])=="--help") {
            std::cout<<"Usage: pentagonal_control [observed30 [expected30 [or|xor|and|fault]]]\n"
                        "Numbers are decimal or 0x-prefixed hexadecimal.\n"
                        "No expected30 means NO independent witness; a missing-witness flag is set.\n";
            return 0;
        }
        const std::uint32_t observed=argc>1?parse30(argv[1]):ligand_mask;
        const std::uint32_t expected=argc>2?parse30(argv[2]):observed;
        const bool supplied=argc>2;
        const Entry entry=argc>3?parse_entry(argv[3]):Entry::or_gate;
        Machine machine{};
        const char* const stages[]={"xor","or","and","nop","cor","flop"};
        Step last{};
        Vista snapshot{};
        std::cout<<"{\"schema\":\"SWE-PENTAGONAL-CXX20-experimental\","
                    "\"source_mutated\":false,"
                    "\"witness_authentication\":\"not_performed\","
                    "\"outer_loop\":\"XOR OR AND NOP COR FLOP return\","
                    "\"stages\":[";
        for(unsigned i=0;i<6;++i) {
            last=machine.tick(observed,expected,entry,supplied);
            if(i) std::cout<<',';
            std::cout<<"{\"name\":\""<<stages[i]<<"\",\"value\":"
                     <<(last.output?"true":"false")<<"}";
            if(i==4) snapshot=last.vista;
        }
        snapshot=pentagonal_vista(snapshot);
        std::cout<<"],\"loops_completed\":"<<machine.loops
                 <<",\"next_stage\":\"xor\""
                 <<",\"witness_supplied\":"<<(supplied?"true":"false")
                 <<",\"logical_evaluations\":"<<snapshot.evaluations
                 <<",\"rupture_flags\":"<<snapshot.rupture
                 <<",\"operand_hex\":\"0x"<<std::hex<<std::setw(16)
                 <<std::setfill('0')<<snapshot.operand<<std::dec<<"\""
                 <<",\"blocks\":[";
        for(unsigned i=0;i<6;++i) {
            if(i) std::cout<<',';
            const auto g=snapshot.blocks[i];
            std::cout<<"{\"xor\":"<<(g.xor_value?"true":"false")
                     <<",\"or\":"<<(g.or_value?"true":"false")
                     <<",\"and\":"<<(g.and_value?"true":"false")<<"}";
        }
        std::cout<<"]}\n";
        return 0;
    }catch(const std::exception& e) {
        std::cerr<<"Pentagonal control rejected input: "<<e.what()<<"\n";
        return 2;
    }
}
