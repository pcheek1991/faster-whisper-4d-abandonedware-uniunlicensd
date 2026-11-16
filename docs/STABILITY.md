# Stability-9L3PX5-U16LE-v1

Canonical authority: external/pentagonal-xor-cpp20/shared/stability10d.hpp at fb23b40480476c98e992762ace37761b6fd8ba0e. The experimental protocol retains its origin in merged PR #17; this document is not an alternate algorithm.

Nine finite ligands h[0..8] must lie in [0,1]. Ring 0 uses indices (0,1,2,3,4); ring 1 uses (3,4,5,6,7); ring 2 uses (6,7,8,0,1). Each calls the original five-input odd-parity kernel, not a clone. For each probability p, quantization is nearest integer with ties upward: floor(65535*p+0.5). Three unsigned 16-bit words are serialized low byte first, for six bytes total.

The Stability scalar equals 1 - (maximum ring result - minimum ring result), bounded [0,1]. This is only an inter-ring mathematical agreement metric, not physical stability or recognition confidence.

The original normalization accepts N frames, mean L/R, RMS L/R, peak L/R and zero crossings L/R. N is a positive exact count bounded to 2^53-1. It uses N/(N+1024), 0.5*(1+m/(1+abs(m))) for signed means, v/(1+v) for nonnegative RMS/peaks, and crossings/max(N-1,1). Invalid domains cannot mutate the output object. Strict C11 parity, 16-minterm references, golden hexabytes and native acoustic measurements are covered by CTest.
