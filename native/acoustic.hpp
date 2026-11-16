// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
// Native stereo float32LE measurement. Inputs remain unchanged and source owned.
#pragma once
#include <array>
#include <istream>
#include <vector>
namespace swe::native {
struct Acoustic {
    std::array<double, 9> measurements{};
    double pearson_lr = 0.0;
    std::vector<float> stereo;
};
Acoustic measure_float32le(std::istream& in);
} // namespace swe::native
