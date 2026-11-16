# DIAMOND security and trust boundaries

All inputs are untrusted. Invalid UTF-8, unrecognized language codes, nonfinite numerical values, overflowed RF calculations, malformed float32LE frames, excessive buffer sizes and contradictory acoustic sources must fail closed without success-looking JSON.

The original five-channel metadata guard requires all channels to pass. XOR is diagnostic only and cannot authorize a release. A 64-digit hash string passing syntax checks does not establish content authenticity or a verified file digest.

Original Pentagonal XOR source and revision remain immutable until explicitly reviewed. The hosted CI jobs check source SHA and collect test/build evidence. The active native engine has no network or speech model dependency. The debug Android package uses temporary keys and requests no network or microphone permission.

Report security concerns privately through repository security advisories. Do not attach live secrets, private recordings or credentials to public issues. Preserve evidence from failed gates and document affected source revisions.
