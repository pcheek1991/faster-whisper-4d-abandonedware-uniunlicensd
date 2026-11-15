# Checkpoint 10 · Distribution rights review

**Status: unresolved, and deliberately not inferred.** This is a
source-and-license provenance checklist, not legal advice or a claim that
the repository is prohibited from all uses.

## Update: mixed license notices on the feature branch

The branch now includes `LICENSE`, `LICENSE-MIT-UPSTREAM`,
`LICENSE-0BSD` and `NOTICE`. The exact SYSTRAN/faster-whisper MIT
license text is preserved for inherited portions, and newly authored
additions marked 0BSD refer to the supporting project's 0BSD terms.
**Neither notice transfers rights to an unrelated third-party tool.**
The bundled DUNGU-derived converter and any separately sourced media
still require their own provenance review. The original absence of a
`LICENSE` on master at the referenced commit remains historical
evidence below, not a description of the current feature branch.

The experimental Android app contains original Java sources, no
pretrained models or network permission. Android SDK/Gradle build tools
are external dependencies and are not relicensed by the project.

## Observed source record (master at 8e379afb)

- No tracked `LICENSE` file is present.
- `setup.py` still declares `license="MIT"`, an MIT classifier, upstream
  `SYSTRAN/faster-whisper` as its project URL and upstream author metadata.
  Metadata is not itself an operative license grant.
- `CITATION.cff` contains submitter-supplied attribution claims. These are
  kept as supplied, not treated as verified authorship, ownership or consent.
- The repository bundles an ONNX model, public test audio, and a PowerShell/C#
  Coreo converter derived from a pinned DUNGU revision. Each component's
  permission and provenance must be independently checked.
- The current workflow previously included automatic PyPI publication on
  version-tag pushes. **Checkpoint 10 removes that automatic step** pending
  a documented rights determination, while retaining local build/tests.

## Required before any new public binary or package publication

1. Identify the exact upstream commit(s), respective license texts,
   copyright notices, applicable obligations and original source records.
2. Establish rights or permission for project modifications, any third-party
   binaries, bundled ONNX weights, audio examples and media assets.
3. Resolve the `setup.py` license classifier/metadata, distribution notices,
   and the missing `LICENSE` file **based on verified legal permissions**.
4. Decide whether the downstream changes can lawfully be distributed as
   0BSD, MIT or another form. Do not assume a fork's name, absent file,
   public GitHub visibility, citation, or an earlier project's license
   creates permission.
5. Record approval, rights evidence, the source commit and manifest, the
   exact release files and their SHA-256 hashes. Then review a separate
   PR to re-enable publication with least-privilege publishing credentials.

The PowerShell source pre-flight supports
`./ci/Test-ReleaseReadiness.ps1 -RequireVerifiedLicense`.
That option **must fail** until a `LICENSE` file exists. Even when it
passes, that alone does not establish ownership or grant completeness.

## Relevant statutory and case context

- [17 U.S.C. § 106](https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title17-section106):
  copyright owners' exclusive reproduction and distribution rights.
- [17 U.S.C. § 117](https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title17-section117):
  limited rules for certain computer-program copies; not a general
  authorization to publish an unrelated third-party codebase.
- [17 U.S.C. § 109](https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title17-section109):
  disposition of particular lawfully made copies; distinguish from
  manufacturing new software distributions.
- *Jacobsen v. Katzer*, 535 F.3d 1373 (Fed. Cir. 2008), concerns license
  conditions under the Artistic License, **not this repository's rights**.
  [Google Scholar search](https://scholar.google.com/scholar?q=Jacobsen+v.+Katzer+535+F.3d+1373).
- *MDY Industries, LLC v. Blizzard Entertainment, Inc.*, 629 F.3d 928
  (9th Cir. 2010), examines copyright-license conditions versus
  contractual covenants in a different license context.
  [Google Scholar search](https://scholar.google.com/scholar?q=MDY+Industries+v.+Blizzard+629+F.3d+928).

No court has been asked to approve or adjudicate this repository through
this change. None of these authorities independently supplies its missing
chain of title.

**Source preserved; uncertainties labeled; release authorization chosen,
never assumed.**
