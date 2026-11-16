// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
//
// I/O ONLY: imports the original, unchanged C11/C++20 operators from the
// pinned Simply-Well-Executed/pentagonal-xor-cpp20 Git submodule.
// No parity, gain, DecaSigma, TriPi, COREAO, or stereo math is reimplemented.
#include "pentagonal_xor_std_free.h"
#include "stability10d.hpp"
#include "deca_sigma.hpp"
#include "tri_pi.hpp"
#include "coreao.hpp"
#include "coreao_gain.hpp"
#include "coreo_stereo.hpp"

#include <cmath>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
double numeric(const char* input) {
    const std::string text(input);
    std::size_t consumed = 0u;
    const double result = std::stod(text, &consumed);
    if (consumed != text.size() || !std::isfinite(result))
        throw std::invalid_argument("Expected one finite numeric operand");
    return result;
}

double bounded(const char* input) {
    const double x = numeric(input);
    if (x < 0.0 || x > 1.0)
        throw std::invalid_argument("Pentagonal XOR feature must be in [0,1]");
    return x;
}

void show_stability(const swe::stability10d::Result& report) {
    char hex[13]{};
    swe::stability10d::hex(report, hex);
    std::cout << "{\"protocol\":\"" << swe::stability10d::protocol
              << "\",\"hexabyte\":\"" << hex
              << "\",\"stability\":" << report.stability
              << ",\"rings\":[" << report.rings[0] << ","
              << report.rings[1] << "," << report.rings[2] << "]"
              << ",\"ring_u16\":[" << report.words[0] << ","
              << report.words[1] << "," << report.words[2] << "]"
              << ",\"admissible\":true}\n";
}

void show_trace(const swe::deca_sigma::Trace& trace) {
    std::cout << "\"operations\":\"" << swe::deca_sigma::operations
              << "\",\"stages\":[";
    for (unsigned i = 0; i < 11u; ++i) {
        if (i) std::cout << ',';
        std::cout << trace.stages[i];
    }
    std::cout << ']';
}

void show_platform() {
    std::cout << "{\"windows\":" << SWE_PXOR_TARGET_WINDOWS
              << ",\"windows_legacy_target\":" << SWE_PXOR_WINDOWS_LEGACY_TARGET
              << ",\"std_free_backend\":" << SWE_PXOR_USE_STDFREE_BACKEND
              << ",\"linux_kernel\":" << SWE_PXOR_TARGET_LINUX_KERNEL
              << ",\"linux\":" << SWE_PXOR_TARGET_LINUX
              << ",\"android\":" << SWE_PXOR_TARGET_ANDROID
              << ",\"unix\":" << SWE_PXOR_TARGET_UNIX
              << ",\"apple\":" << SWE_PXOR_TARGET_APPLE << "}\n";
}

void show_coreo_stereo(int argc, char** argv) {
    // CLI limit controls input allocation, not the imported algorithm.
    if (argc < 4 || ((argc - 2) % 2) != 0 || argc > 8194)
        throw std::invalid_argument("coreo-stereo requires 1..4096 L/R frame pairs");
    const unsigned long long frames = static_cast<unsigned long long>((argc - 2) / 2);
    std::vector<float> original;
    original.reserve(static_cast<std::size_t>(frames) * 2u);
    for (int i = 2; i < argc; ++i) {
        const double value = numeric(argv[i]);
        if (value > std::numeric_limits<float>::max() ||
            value < -std::numeric_limits<float>::max())
            throw std::invalid_argument("float32 input outside finite range");
        original.push_back(static_cast<float>(value));
    }
    std::vector<swe::coreo_stereo::Quad> quad(static_cast<std::size_t>(frames));
    std::vector<float> recovered;
    recovered.reserve(original.size());
    for (unsigned long long i = 0u; i < frames; ++i) {
        if (!swe::coreo_stereo::forward_at(original.data(), frames, i, quad[static_cast<std::size_t>(i)]))
            throw std::invalid_argument("Original COREO forward operator rejected frame");
        float l = 0.0f, r = 0.0f;
        if (!swe::coreo_stereo::reverse_at(quad[static_cast<std::size_t>(i)], l, r))
            throw std::invalid_argument("Original COREO inverse operator rejected frame");
        recovered.push_back(l);
        recovered.push_back(r);
    }
    const auto audit = swe::coreo_stereo::inspect(original.data(), frames, quad.data());
    if (!audit.admissible)
        throw std::invalid_argument("Original COREO Z-fold audit rejected input");
    std::cout << "{\"frames\":" << frames << ",\"original\":[";
    for (std::size_t i = 0; i < original.size(); ++i) {
        if (i) std::cout << ',';
        std::cout << original[i];
    }
    std::cout << "],\"quad\":[";
    for (std::size_t i = 0; i < quad.size(); ++i) {
        if (i) std::cout << ',';
        const auto& q = quad[i];
        std::cout << '[' << q.yin_left << ',' << q.yin_right << ','
                  << q.yang_left << ',' << q.yang_right << ']';
    }
    std::cout << "],\"recovered\":[";
    for (std::size_t i = 0; i < recovered.size(); ++i) {
        if (i) std::cout << ',';
        std::cout << recovered[i];
    }
    std::cout << "],\"largest_disagreement\":" << audit.largest_disagreement
              << ",\"admissible\":true}\n";
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc < 2) throw std::invalid_argument("Expected a canonical operator mode");
        const std::string mode(argv[1]);
        std::cout << std::setprecision(17);
        if (mode == "platform" && argc == 2) {
            show_platform();
            return 0;
        }
        if ((mode == "parity" || mode == "scores") && argc == 7) {
            const Features5 f = {
                bounded(argv[2]), bounded(argv[3]), bounded(argv[4]),
                bounded(argv[5]), bounded(argv[6])
            };
            if (mode == "parity") {
                const double v[5] = {f.h0, f.h1, f.h2, f.h3, f.h4};
                std::cout << "{\"algorithm\":\"swe_pxor_xor_parity_arr\",\"score\":"
                          << swe_pxor_xor_parity_arr(v) << "}\n";
            } else {
                const PentagonalScores scores = swe_pxor_scores5(f);
                std::cout << "{\"algorithm\":\"swe_pxor_scores5\""
                          << ",\"and\":" << scores.and_score
                          << ",\"or\":" << scores.or_score
                          << ",\"xor\":" << scores.xor_score
                          << ",\"partial\":" << scores.partial
                          << ",\"legacy_fifth_root\":" << scores.legacy << "}\n";
            }
            return 0;
        }
        if (mode == "fifth-root" && argc == 3) {
            std::cout << "{\"algorithm\":\"swe_pxor_fifth_root\",\"value\":"
                      << swe_pxor_fifth_root(numeric(argv[2])) << "}\n";
            return 0;
        }
        if ((mode == "ligands" || mode == "measurements") && argc == 11) {
            double values[9]{};
            for (int i = 0; i < 9; ++i) values[i] = numeric(argv[i + 2]);
            swe::stability10d::Result result{};
            const bool admissible = mode == "ligands"
                ? swe::stability10d::calculate(values, result)
                : swe::stability10d::from_measurements(values, result);
            if (!admissible)
                throw std::invalid_argument("Canonical Stability guard rejected input");
            show_stability(result);
            return 0;
        }
        if ((mode == "deca-sigma" || mode == "tri-pi" || mode == "coreao") &&
            argc == 3) {
            const auto trace = swe::deca_sigma::run(numeric(argv[2]));
            if (!trace.admissible)
                throw std::invalid_argument("Original DecaSigma domain rejected input");
            std::cout << "{\"algorithm\":\"" << mode << "\",";
            show_trace(trace);
            if (mode == "deca-sigma") {
                std::cout << ",\"returned\":"
                          << (swe::deca_sigma::witnesses_return(trace) ? "true" : "false");
            } else if (mode == "tri-pi") {
                const auto report = swe::tri_pi::inspect(trace);
                std::cout << ",\"forward\":" << (report.forward ? "true" : "false")
                          << ",\"reverse\":" << (report.reverse ? "true" : "false")
                          << ",\"zfold\":" << (report.zfold ? "true" : "false")
                          << ",\"passed\":" << (report.passed() ? "true" : "false");
            } else {
                const auto report = swe::coreao::inspect(trace);
                std::cout << ",\"scalar\":" << report.scalar
                          << ",\"admissible\":" << (report.admissible ? "true" : "false")
                          << ",\"passed\":" << (report.passed() ? "true" : "false");
            }
            std::cout << "}\n";
            return 0;
        }
        if (mode == "gain9dbi" && argc == 3) {
            // RF directional EIRP ONLY. Never reinterpret dBi as audio dB.
            const auto report = swe::coreao::rf_gain::apply(numeric(argv[2]));
            if (!report.admissible)
                throw std::invalid_argument("Original COREAO +9 dBi RF gain rejected watts");
            std::cout << "{\"algorithm\":\"swe::coreao::rf_gain::apply\""
                      << ",\"domain\":\"idealized-rf-eirp\""
                      << ",\"input_watts\":" << report.input_watts
                      << ",\"gain_dbi\":" << report.gain_dbi
                      << ",\"gain_linear\":" << report.gain_linear
                      << ",\"field_factor\":" << swe::coreao::rf_gain::field_factor
                      << ",\"output_eirp_watts\":" << report.output_eirp_watts
                      << ",\"recovered_input_watts\":" << report.recovered_input_watts
                      << ",\"normalized_residual\":" << report.normalized_residual
                      << ",\"admissible\":true"
                      << ",\"passed\":" << (report.passed() ? "true" : "false") << "}\n";
            return 0;
        }
        if (mode == "coreo-stereo") {
            show_coreo_stereo(argc, argv);
            return 0;
        }
        throw std::invalid_argument(
            "usage: parity|scores <5> | fifth-root <1> | ligands|measurements <9> | "
            "deca-sigma|tri-pi|coreao|gain9dbi <1> | coreo-stereo <L/R frames> | platform");
    } catch (const std::exception& error) {
        std::cerr << "Canonical upstream adapter rejected: " << error.what() << '\n';
        return 2;
    }
}
