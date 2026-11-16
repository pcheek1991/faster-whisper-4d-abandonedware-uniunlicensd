// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
// Native C++20 measurement: no decoder, network or foreign DSP library.
#include "acoustic.hpp"
#include <algorithm>
#include <bit>
#include <cmath>
#include <cstdint>
#include <limits>
#include <stdexcept>
namespace swe::native {
namespace {
float little_f32(const unsigned char* p) {
    const std::uint32_t word =
        std::uint32_t(p[0]) | (std::uint32_t(p[1]) << 8u) |
        (std::uint32_t(p[2]) << 16u) | (std::uint32_t(p[3]) << 24u);
    return std::bit_cast<float>(word);
}
} // namespace
Acoustic measure_float32le(std::istream& in) {
    static_assert(sizeof(float) == 4, "The source format requires binary32");
    static_assert(std::numeric_limits<float>::is_iec559, "IEEE-754 floats required");
    Acoustic result{};
    constexpr std::size_t max_frames = 1'000'000u;
    double mean_l = 0.0, mean_r = 0.0, m2_l = 0.0, m2_r = 0.0;
    double covariance = 0.0, power_l = 0.0, power_r = 0.0;
    double peak_l = 0.0, peak_r = 0.0;
    double crossings_l = 0.0, crossings_r = 0.0;
    double prev_l = 0.0, prev_r = 0.0;
    std::size_t count = 0;
    for (;;) {
        unsigned char frame[8]{};
        in.read(reinterpret_cast<char*>(frame), sizeof(frame));
        const auto bytes = in.gcount();
        if (bytes == 0 && in.eof()) break;
        if (bytes != static_cast<std::streamsize>(sizeof(frame)))
            throw std::invalid_argument("Truncated stereo float32LE frame");
        if (count == max_frames)
            throw std::invalid_argument("Input exceeds 1,000,000-frame memory boundary");
        const float lf = little_f32(frame), rf = little_f32(frame + 4);
        if (!std::isfinite(lf) || !std::isfinite(rf))
            throw std::invalid_argument("Nonfinite stereo sample");
        const double l = lf, r = rf;
        if (count > 0) {
            if (prev_l != 0.0 && l != 0.0 && ((prev_l < 0.0) != (l < 0.0)))
                ++crossings_l;
            if (prev_r != 0.0 && r != 0.0 && ((prev_r < 0.0) != (r < 0.0)))
                ++crossings_r;
        }
        ++count;
        const double dl = l - mean_l, dr = r - mean_r;
        mean_l += dl / static_cast<double>(count);
        mean_r += dr / static_cast<double>(count);
        m2_l += dl * (l - mean_l);
        m2_r += dr * (r - mean_r);
        covariance += dl * (r - mean_r);
        power_l += l * l;
        power_r += r * r;
        peak_l = std::max(peak_l, std::abs(l));
        peak_r = std::max(peak_r, std::abs(r));
        prev_l = l;
        prev_r = r;
        result.stereo.push_back(lf);
        result.stereo.push_back(rf);
    }
    if (!in.eof() && !in.good()) throw std::runtime_error("Read error in audio source");
    if (count == 0) throw std::invalid_argument("Empty stereo source");
    const double n = static_cast<double>(count);
    if (m2_l > 0.0 && m2_r > 0.0) {
        result.pearson_lr = covariance / std::sqrt(m2_l * m2_r);
        result.pearson_lr = std::clamp(result.pearson_lr, -1.0, 1.0);
    }
    result.measurements = {n, mean_l, mean_r,
        std::sqrt(power_l / n), std::sqrt(power_r / n),
        peak_l, peak_r, crossings_l, crossings_r};
    return result;
}
} // namespace swe::native
