# Contributing to faster-whisper

Contributions are welcome! Here are some pointers to help you install the library for development and validate your changes before submitting a pull request.

## Install the library for development

Python 3.12 or newer is required.

Save Markdown and Python source as UTF-8 without a byte-order mark. For Unicode or bidirectional
text changes, preserve logical codepoint order and add codepoint-level tests; do not insert, strip,
or normalize direction controls without an explicit requirement. Follow the
[Unicode Bidirectional Algorithm (UAX #9)](https://www.unicode.org/reports/tr9/) and the
[W3C inline bidi markup guidance](https://www.w3.org/International/articles/inline-bidi-markup/)
when documenting rendering behavior.

We recommend installing the module in editable mode with the `dev` extra requirements:

```bash
git clone https://github.com/SYSTRAN/faster-whisper.git
cd faster-whisper/
pip install -e ".[dev]"
```

## Validate the changes before creating a pull request

1. Run deterministic validation tests and model integration tests separately:

```bash
python -m pytest -q -m "not integration"
python -m pytest -v -m integration
```

2. Reformat and validate the code with the following tools:

```bash
black --check .
isort --check-only .
flake8 .
```

<span style="color:#b00020;"><u>CONFIGURED, NOT YET RUN REMOTELY:</u></span> These checks are
configured in GitHub Actions; the workflow for this branch has not yet completed on GitHub.

For the project validation scope, risk traceability, and known evidence limitations, see
[VALIDATION.md](VALIDATION.md). The integration tests download model weights from the Hugging Face
Hub when they are not cached, so the first full run requires network access.
