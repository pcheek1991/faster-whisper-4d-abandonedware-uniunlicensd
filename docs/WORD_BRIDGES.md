# Word Bridges: Wikipedia language registry (native C++20)

This repository embeds an **offline list of 348 active Wikipedia language editions**, including exact language codes, English names, local autonyms, and Wikipedia edition URLs. This catalog is data for selecting and labeling language spans; it is **not a translation engine, model, pronunciation dictionary or a guarantee of linguistic fluency**.

**Authoritative facts:** Wikimedia Meta-Wiki [List of Wikipedias](https://meta.wikimedia.org/wiki/List_of_Wikipedias) and its `action=sitematrix` API. Snapshot adapted from `entitizer/wikipedia-data`, `data/languages.json`, Git blob `5f97e44d943f1a5e4c89acce23c5a43afb3fc92d`, data generated `2026-09-08T07:06:19.300Z`, 348 entries. The embedded `native/wikimedia_languages.inc` contains the same names/code points, serialized as UTF-8 C++20 literals. ISC license and copyright are retained in `LICENSE-ISC-WIKIPEDIA-DATA`. Updating the catalog requires reviewing a newer source snapshot, updating the snapshot and the C++ literal file together, and recording the change.

**Scope boundary:** The separately hosted ChatGPT profile site named *Word Bridges* could not be independently located or read during this change. We therefore cannot assert its list is identical or that its content has been imported. The older Hanzeye site is a separate project. This registry uses the verifiable Wikimedia catalog rather than fabricating a personal-site snapshot.

The native bridge stores `language`, `character/text`, `reading`, `meaning`, and `source` as **separate caller-owned fields**. Original UTF-8 bytes and code points are not silently normalized, reshaped, transliterated, or translated. Invalid UTF-8 is rejected. Script direction is left `auto` unless explicitly supplied by the author. No missing reading or meaning is invented; callers can supply them, leave them empty, or mark them unknown.

To list languages, run `diamond --languages` after compiling. To select a language, use `diamond --language fa`; to label source text, append `--text`, `--reading`, `--meaning`, and `--source`. All math facets run independently of which language was selected. The output explicitly reports what language metadata is supported and which content has not been translated or interpreted.

**Licensing:** The data snapshot's ISC obligations are retained; the canonical Pentagonal XOR project source remains independently pinned and licensed 0BSD. Platform SDK and compiler licenses remain distinct.
