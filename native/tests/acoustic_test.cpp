// SPDX-License-Identifier: 0BSD
#include "acoustic.hpp"
#include "stability10d.hpp"
#include "coreo_stereo.hpp"
#include <array>
#include <cassert>
#include <cmath>
#include <sstream>
#include <stdexcept>
int main() {
    using swe::native::measure_float32le;
    // Original synthetic three-frame witness: L=1,2,3; R=10,20,30.
    const std::array<unsigned char,24> bytes = {
        0,0,128,63, 0,0,32,65, 0,0,0,64, 0,0,160,65,
        0,0,64,64, 0,0,240,65
    };
    const std::string raw(reinterpret_cast<const char*>(bytes.data()),bytes.size());
    std::istringstream in(raw);
    const auto report = measure_float32le(in);
    assert(report.stereo.size()==6u);
    assert(report.measurements[0]==3.0);
    assert(std::abs(report.measurements[1]-2.0)<1e-12);
    assert(std::abs(report.measurements[2]-20.0)<1e-12);
    assert(std::abs(report.measurements[3]-std::sqrt(14.0/3.0))<1e-12);
    assert(std::abs(report.measurements[4]-std::sqrt(1400.0/3.0))<1e-12);
    assert(report.measurements[7]==0.0);
    assert(report.measurements[8]==0.0);
    assert(std::abs(report.pearson_lr-1.0)<1e-12);
    double nine[9]{};
    for(unsigned i=0;i<9;++i)nine[i]=report.measurements[i];
    swe::stability10d::Result stability{};
    assert(swe::stability10d::from_measurements(nine,stability));
    assert(stability.admissible);
    swe::coreo_stereo::Quad quad[3]{};
    for(unsigned long long i=0;i<3;++i) {
        assert(swe::coreo_stereo::forward_at(report.stereo.data(),3,i,quad[i]));
        float l=0,r=0;
        assert(swe::coreo_stereo::reverse_at(quad[i],l,r));
        assert(l==report.stereo[2*i] && r==report.stereo[2*i+1]);
    }
    const auto audit=swe::coreo_stereo::inspect(report.stereo.data(),3,quad);
    assert(audit.admissible && audit.largest_disagreement==0.0);
    auto rejects=[](const std::string& data){
        std::istringstream stream(data);
        try {(void)measure_float32le(stream);return false;}
        catch(const std::invalid_argument&){return true;}
    };
    assert(rejects({}));
    assert(rejects(raw.substr(0,raw.size()-1)));
    const std::string nan_frame("\0\0\xc0\x7f\0\0\x80\x3f",8);
    assert(rejects(nan_frame));
    return 0;
}
