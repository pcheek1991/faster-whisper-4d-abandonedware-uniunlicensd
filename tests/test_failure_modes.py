import logging
import shutil
import sys

from pathlib import Path
from types import SimpleNamespace

import numpy as np
import pytest

import faster_whisper.audio as audio_module
import faster_whisper.transcribe as transcribe_module
import faster_whisper.utils as utils_module

from faster_whisper.tokenizer import Tokenizer
from faster_whisper.vad import SileroVADModel, VadOptions


class FakeFeatureExtractor:
    sampling_rate = 16000
    chunk_length = 30

    def __call__(self, audio):
        return np.zeros((80, 2), dtype=np.float32)


def make_batched_pipeline(monkeypatch):
    model = SimpleNamespace(
        feature_extractor=FakeFeatureExtractor(),
        model=SimpleNamespace(is_multilingual=False),
        logger=logging.getLogger("faster_whisper.test"),
        hf_tokenizer=None,
    )
    pipeline = transcribe_module.BatchedInferencePipeline(model)

    monkeypatch.setattr(
        transcribe_module,
        "Tokenizer",
        lambda *args, **kwargs: object(),
    )
    monkeypatch.setattr(
        transcribe_module,
        "get_speech_timestamps",
        lambda audio, options: [{"start": 0, "end": len(audio)}],
    )
    monkeypatch.setattr(
        pipeline,
        "_batched_segments_generator",
        lambda *args: iter(()),
    )

    return pipeline


@pytest.mark.parametrize(
    "vad_parameters",
    [
        pytest.param(
            {"threshold": 0.7, "max_speech_duration_s": 45},
            id="dict",
        ),
        pytest.param(
            VadOptions(threshold=0.7, max_speech_duration_s=45),
            id="dataclass",
        ),
    ],
)
def test_batched_vad_options_are_bounded_without_mutating_input(
    monkeypatch, vad_parameters
):
    original_parameters = (
        dict(vad_parameters) if isinstance(vad_parameters, dict) else vad_parameters
    )
    pipeline = make_batched_pipeline(monkeypatch)

    _, info = pipeline.transcribe(
        np.zeros(16000, dtype=np.float32),
        language="en",
        vad_filter=True,
        vad_parameters=vad_parameters,
        suppress_tokens=[],
    )

    assert info.vad_options.max_speech_duration_s == 30
    if isinstance(vad_parameters, dict):
        assert vad_parameters == original_parameters
    else:
        assert vad_parameters.max_speech_duration_s == 45
        assert info.vad_options is not vad_parameters


def test_model_files_argument_is_not_mutated(monkeypatch):
    captured = {}

    class FakeWhisper:
        def __new__(cls, model_path, **kwargs):
            captured["files"] = kwargs["files"]
            return SimpleNamespace(is_multilingual=False)

    class FakeTokenizer:
        @staticmethod
        def from_buffer(_):
            return object()

    monkeypatch.setattr(transcribe_module.ctranslate2.models, "Whisper", FakeWhisper)
    monkeypatch.setattr(transcribe_module.tokenizers, "Tokenizer", FakeTokenizer)

    files = {
        "model.bin": b"weights",
        "tokenizer.json": b"tokenizer",
        "preprocessor_config.json": b'{"sampling_rate": 16000, "hop_length": 160}',
    }
    original_files = files.copy()

    transcribe_module.WhisperModel("memory-model", files=files)

    assert files == original_files
    assert captured["files"] == {"model.bin": b"weights"}


def test_hub_download_failure_is_propagated(monkeypatch):
    error = ConnectionError("hub unavailable")

    def fail_download(*args, **kwargs):
        raise error

    monkeypatch.setattr(
        utils_module.huggingface_hub, "snapshot_download", fail_download
    )

    with pytest.raises(ConnectionError, match="hub unavailable") as exc_info:
        utils_module.download_model("tiny")

    assert exc_info.value is error


def test_audio_open_failure_is_propagated(monkeypatch):
    error = OSError("media unavailable")

    def fail_open(*args, **kwargs):
        raise error

    monkeypatch.setattr(audio_module.av, "open", fail_open)

    with pytest.raises(OSError, match="media unavailable") as exc_info:
        audio_module.decode_audio("broken.wav")

    assert exc_info.value is error


def test_missing_vad_runtime_is_explicit(monkeypatch):
    monkeypatch.setitem(sys.modules, "onnxruntime", None)

    with pytest.raises(
        RuntimeError, match="requires the onnxruntime package"
    ) as exc_info:
        SileroVADModel("unused.onnx")

    assert isinstance(exc_info.value.__cause__, ImportError)


@pytest.mark.parametrize(
    "audio, message",
    [
        (np.zeros((2, 512), dtype=np.float32), "1D"),
        (np.zeros(513, dtype=np.float32), "multiple"),
    ],
)
def test_vad_rejects_invalid_audio_before_inference(audio, message):
    vad_model = object.__new__(SileroVADModel)

    with pytest.raises(AssertionError, match=message):
        vad_model(audio)


def test_vad_default_minimum_silence_duration():
    assert VadOptions().min_silence_duration_ms == 2000


def test_audio_decode_does_not_require_ffmpeg_cli(jfk_path, monkeypatch, tmp_path):
    monkeypatch.setenv("PATH", str(tmp_path))
    assert shutil.which("ffmpeg") is None

    audio = audio_module.decode_audio(jfk_path)

    assert audio.dtype == np.float32
    assert audio.size > 0


def test_tokenizer_decode_preserves_bidi_controls():
    text = (
        "\u2068\u0627\u0644\u0639\u0631\u0628\u064a\u0629\u2069\n"
        "\u200eA\u200f\u200d\u200c"
    )
    expected_codepoints = (
        0x2068,
        0x0627,
        0x0644,
        0x0639,
        0x0631,
        0x0628,
        0x064A,
        0x0629,
        0x2069,
        0x000A,
        0x200E,
        0x0041,
        0x200F,
        0x200D,
        0x200C,
    )

    class FakeTokenizer:
        def token_to_id(self, _):
            return 2

        def decode(self, _):
            return text

    decoded = Tokenizer(FakeTokenizer(), multilingual=False).decode([1])

    assert tuple(map(ord, decoded)) == expected_codepoints


def test_markdown_docs_are_utf8_without_bom():
    repository_root = Path(__file__).resolve().parents[1]

    for filename in ("README.md", "CONTRIBUTING.md", "VALIDATION.md"):
        content = (repository_root / filename).read_bytes()
        assert not content.startswith(b"\xef\xbb\xbf"), filename
        content.decode("utf-8")
