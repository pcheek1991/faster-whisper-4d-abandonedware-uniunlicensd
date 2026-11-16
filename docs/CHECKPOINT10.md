# Checkpoint 10: original acoustic source and witnesses

The input format is raw interleaved stereo IEEE-754 float32 little-endian: L0,R0,L1,R1, etc. The native C++20 reader computes nine source measurements in fixed order: frame count; left/right means; left/right RMS; left/right maximum absolute peaks; left/right zero-crossing counts.

Dimension ten is the unchanged original Stability-9L3PX5-U16LE-v1 scalar, calculated by the pinned upstream header. It normalizes nine source measurements, evaluates three overlapping five-input odd-parity rings, quantizes the results to three 16-bit words and emits a six-byte little-endian hexabyte. The source array is never silently replaced.

The synthetic three-frame test uses L=(1,2,3) and R=(10,20,30), verifying the source means, RMS, crossings, original normalization and COREO reversible stereo. Invalid nonfinite data, incomplete frames, empty sources and oversized buffers fail closed. Current native raw audio is limited to 1,000,000 stereo frames and does not decode media containers.

A no-input CLI execution uses clearly labeled reference fixtures, not invented microphone or antenna measurements. It does not transcribe speech, compute speaker identity or establish an independently calibrated acoustic quality score. The original second-wave counterarccosine remains exploratory research.

See VALIDATION.md and docs/PENTAGONAL_XOR_PROVENANCE.md for test and source details.
