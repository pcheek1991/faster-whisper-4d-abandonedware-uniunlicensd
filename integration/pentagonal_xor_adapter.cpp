// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
// Thin I/O adapter only. All mathematical functions are in upstream verbatim.
#include "pentagonal_xor_std_free.h"
#include "stability10d.hpp"
#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
namespace {
double parse(const char* raw) {
  const std::string input(raw);
  std::size_t end = 0;
  const double value = std::stod(input, &end);
  if (end != input.size() || !std::isfinite(value))
    throw std::invalid_argument("nonfinite or malformed number");
  return value;
}
void display(const swe::stability10d::Result& report) {
  char hex[13]{};
  swe::stability10d::hex(report, hex);
  std::cout << "{\"protocol\":\"" << swe::stability10d::protocol
            << "\",\"hexabyte\":\"" << hex
            << "\",\"stability\":" << report.stability
            << ",\"rings\":[" << report.rings[0] << ","
            << report.rings[1] << "," << report.rings[2] << "]}\n";
}
}
int main(int argc, char** argv) {
  try {
    if (argc < 2) throw std::invalid_argument("select parity, ligands or measurements");
    const std::string mode(argv[1]);
    std::cout << std::setprecision(17);
    if (mode == "parity" && argc == 7) {
      double five[5]{};
      for (int i = 0; i < 5; ++i) {
        five[i] = parse(argv[i + 2]);
        if (five[i] < 0.0 || five[i] > 1.0)
          throw std::invalid_argument("parity input outside [0,1]");
      }
      std::cout << "{\"algorithm\":\"swe_pxor_xor_parity_arr\",\"score\":"
                << swe_pxor_xor_parity_arr(five) << "}\n";
      return 0;
    }
    if ((mode == "ligands" || mode == "measurements") && argc == 11) {
      double nine[9]{};
      for (int i = 0; i < 9; ++i) nine[i] = parse(argv[i + 2]);
      swe::stability10d::Result report{};
      const bool valid = mode == "ligands"
          ? swe::stability10d::calculate(nine, report)
          : swe::stability10d::from_measurements(nine, report);
      if (!valid) throw std::invalid_argument("canonical Stability guard rejected input");
      display(report);
      return 0;
    }
    throw std::invalid_argument("usage: parity <5> | ligands <9> | measurements <9>");
  } catch (const std::exception& error) {
    std::cerr << "Upstream adapter rejected: " << error.what() << '\n';
    return 2;
  }
}
