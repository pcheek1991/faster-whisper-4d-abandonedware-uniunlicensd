// SPDX-License-Identifier: 0BSD
// Same semantic COR workload as java/LigazeJavaBenchmark.java.
// Output one JSON object; use only within-runner measurements.
#include "../pentagonal_ligaze.hpp"
#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <vector>

namespace {
constexpr std::uint32_t seed=0x0badf00du;
constexpr unsigned intended=0x15u, required=0x1fu;
struct Sample { double ns{}; std::uint64_t checksum{}; };
std::uint64_t checked(std::uint32_t& state) {
    state=state*1664525u+1013904223u;
    const auto raw=static_cast<std::uint8_t>((state>>8u)&31u);
    const auto conf=static_cast<std::uint8_t>((state>>16u)&31u);
    const auto held=swe::ligaze::hold(raw,intended,conf,required);
    const unsigned expected=(raw==intended?0u:17u)|(conf==required?0u:4u);
    if(held.witness.rupture!=expected || held.witness.evaluations!=96u ||
       held.witness.observed!=swe::ligaze::blocks(raw,intended,conf,required))
        throw std::runtime_error("COR parity/evidence mismatch");
    return static_cast<std::uint64_t>(expected*131u+raw+conf);
}
void securityChecks() {
    using swe::ligaze::hold;
    auto intact=hold(0x15u,0x15u,0x1fu,0x1fu);
    auto flipped=hold(0x14u,0x15u,0x1fu,0x1fu);
    auto forgedBoth=hold(0x14u,0x14u,0x1fu,0x1fu);
    auto conformanceFlipped=hold(0x15u,0x15u,0x1eu,0x1fu);
    auto repeated=hold(0x15u,0x15u,0x1fu,0x1fu);
    const auto missing=swe::pentagonal::pentagonal_cor(31u,31u,
      swe::pentagonal::Entry::or_gate,false,true,true);
    const auto clock=swe::pentagonal::pentagonal_cor(31u,31u,
      swe::pentagonal::Entry::or_gate,true,true,false);
    const auto replay=swe::pentagonal::pentagonal_cor(31u,31u,
      swe::pentagonal::Entry::or_gate,true,false,true);
    if(intact.witness.rupture!=0u || flipped.witness.rupture!=17u ||
       forgedBoth.witness.rupture!=0u || !forgedBoth.matches_expected_behavior ||
       conformanceFlipped.witness.rupture!=4u ||
       repeated.witness.operand!=intact.witness.operand ||
       (missing.rupture&swe::pentagonal::missing_witness)==0 ||
       (clock.rupture&swe::pentagonal::clock_regression)==0 ||
       (replay.rupture&swe::pentagonal::replay_sequence)==0)
        throw std::runtime_error("COR threat-model fixture mismatch");
}
int sizeArg(const char* s,int limit) {
    const long v=std::strtol(s,nullptr,10);
    if(v<1 || v>limit) throw std::invalid_argument("invalid sample count");
    return static_cast<int>(v);
}
}
int main(int argc,char** argv) {
    try {
        if(argc!=4) throw std::invalid_argument("Usage: pentagonal_ligaze_benchmark iterations warmup repeats");
        const int iterations=sizeArg(argv[1],10000000);
        const int warmup=sizeArg(argv[2],10000000);
        const int repeats=sizeArg(argv[3],11);
        securityChecks();
        std::uint32_t prep=seed;
        std::uint64_t warming=0;
        for(int i=0;i<warmup;++i) warming+=checked(prep);
        if(warming==0) throw std::runtime_error("warmup not executed");
        std::vector<double> timings;
        timings.reserve(static_cast<std::size_t>(repeats));
        std::uint64_t baseline=0;
        for(int round=0;round<repeats;++round) {
            std::uint32_t state=seed;
            std::uint64_t checksum=0;
            auto t0=std::chrono::steady_clock::now();
            for(int i=0;i<iterations;++i) checksum+=checked(state);
            const auto t1=std::chrono::steady_clock::now();
            if(round>0 && checksum!=baseline) throw std::runtime_error("nondeterministic native checksum");
            if(round==0) baseline=checksum;
            timings.push_back(std::chrono::duration<double,std::nano>(t1-t0).count()/iterations);
        }
        auto ordered=timings;
        std::sort(ordered.begin(),ordered.end());
        const double median=ordered[ordered.size()/2u];
        if(!std::isfinite(median) || median<=0) throw std::runtime_error("invalid measurement");
        std::cout<<std::fixed<<std::setprecision(4)
                 <<"{\"schema\":\"SWE-LIGAZE-BENCH-v1\",\"runtime\":\"native-cxx20\","
                 <<"\"iterations\":"<<iterations<<",\"warmup\":"<<warmup
                 <<",\"repeats\":"<<repeats<<",\"median_ns_per_call\":"<<median
                 <<",\"checksum\":"<<baseline<<",\"samples_ns_per_call\":[";
        for(std::size_t i=0;i<timings.size();++i){
            if(i) std::cout<<',';
            std::cout<<timings[i];
        }
        std::cout<<"],\"threat_fixtures\":\"PASS\","
                    "\"same_inputs_and_expected_fixture\":true,"
                    "\"external_authentication\":false}\n";
        return 0;
    } catch(const std::exception& e) {
        std::cerr<<"LIGAZE_BENCH_ERROR: "<<e.what()<<"\n";return 2;
    }
}
