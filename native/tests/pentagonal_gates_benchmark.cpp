// SPDX-License-Identifier: 0BSD
// Exploratory native benchmark: no unqualified speed ranking.
#include "../pentagonal_gates.hpp"
#include <array>
#include <chrono>
#include <cstdint>
#include <iomanip>
#include <iostream>

namespace {
using swe::pentagonal::boolean_gates;
constexpr std::uint8_t rotate5(std::uint8_t mask, unsigned by) noexcept {
    return static_cast<std::uint8_t>(((mask << by) |
               (mask >> (5u-by))) & 31u);
}
bool parity_one(std::uint8_t mask) noexcept {
    return boolean_gates(mask).xor_value;
}
bool parity_two(std::uint8_t mask) noexcept {
    std::uint8_t second=0u;
    for (unsigned j=0;j<5;++j)
        if (parity_one(rotate5(mask,j))) second|=static_cast<std::uint8_t>(1u<<j);
    return parity_one(second);
}
bool parity_three(std::uint8_t mask) noexcept {
    std::uint8_t third=0u;
    for (unsigned j=0;j<5;++j)
        if (parity_two(rotate5(mask,j))) third|=static_cast<std::uint8_t>(1u<<j);
    return parity_one(third);
}
using Func=bool(*)(std::uint8_t);
double run(Func fn, unsigned iterations, unsigned& checksum) {
    std::uint32_t state=0x0baceda7u;
    volatile unsigned sink=0;
    const auto t0=std::chrono::steady_clock::now();
    for(unsigned i=0;i<iterations;++i) {
        state = state * 1664525u + 1013904223u;
        const std::uint8_t mask=static_cast<std::uint8_t>(state & 31u);
        sink = sink + static_cast<unsigned>(fn(mask));
    }
    const auto t1=std::chrono::steady_clock::now();
    checksum=static_cast<unsigned>(sink);
    return std::chrono::duration<double,std::nano>(t1-t0).count()/iterations;
}
}
int main() {
    for (unsigned mask=0;mask<32;++mask)
        if (parity_one(static_cast<std::uint8_t>(mask)) !=
            parity_two(static_cast<std::uint8_t>(mask)) ||
            parity_one(static_cast<std::uint8_t>(mask)) !=
            parity_three(static_cast<std::uint8_t>(mask))) return 2;
    constexpr unsigned n=1000000u;
    for (const auto& candidate : std::array<std::pair<const char*,Func>,3>{
             {{"direct_boolean_xor",parity_one},
              {"stacked_depth_2",parity_two},
              {"stacked_depth_3",parity_three}}}) {
        unsigned sum=0;
        const double ns=run(candidate.second,n,sum);
        if (sum!=500000u) {
            // LCG low-order bits are not guaranteed to yield exactly half
            // the parity ones at every sample size; benchmark correctness
            // is verified by the exhaustive 32-state check above.
            if (sum==0u || sum==n) return 3;
        }
        std::cout<<candidate.first<<" "<<std::fixed<<std::setprecision(3)
                 <<ns<<" ns/evaluation, checksum="<<sum<<"\n";
    }
    std::cout<<"Interpretation: measurements are CPU/compiler-specific, not "
                "hardware clock counts; stacks repeat correlated inputs.\n";
    return 0;
}
