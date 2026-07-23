# WazobiaVoice TTS

Nigerian multilingual text-to-speech — **Yoruba, Hausa, Igbo, Nigerian Pidgin,
and Nigerian-accented English** — with zero-shot voice cloning, built by
[Axiveri]((https://huggingface.co/Axiveri)), an African AI research initiative.

Model weights and card: [huggingface.co/Axiveri/WazobiaVoice](https://huggingface.co/Axiveri/WazobiaVoice)

---

## Install

This install is staged deliberately — a plain `pip install .` will fail on
this stack (deepfilternet and torchmetrics send pip's resolver backtracking
into years-old, incompatible releases hunting for a stale pin match). Use
the install script instead:

```bash
git clone https://github.com/Ememzyvisuals/wazobiavoice-TTS.git
cd wazobiavoice-TTS
bash scripts/install.sh
```

That script:
- installs `cargo`/`rustc` so `deepfilternet`'s Rust extension (`libdf`) builds from source (no prebuilt wheel exists for Python 3.12)
- installs numpy/torch/torchaudio first, as the only thing later stages assume is present
- installs the data/hub libraries, then `torchmetrics[audio]` pinned to `>=1.4` (unpinned, its resolver wanders into 2021-era releases)
- installs `maturin` explicitly (needed as `deepfilterlib`'s declared build backend before build isolation gets turned off)
- installs the remaining audio libraries with `--no-build-isolation`, so their legacy `setup.py` scripts can see the already-installed numpy instead of building in an empty isolated env
- installs `deepfilternet`/`deepfilterlib` with `--no-deps`, bypassing a stale `numpy<2.0` pin in their own package metadata that's over-strict for this environment (confirmed working with numpy 2.x at runtime)
- installs this package itself last, with `--no-deps`, since everything real above is already handled correctly

Full reasoning for each step is commented inline in `scripts/install.sh`.

**Requirements:** Python 3.10+, a CUDA GPU recommended (CPU works but is slow).

---

## Quickstart

```python
import torch
import torchaudio as ta
from wazobiavoice_tts.mtl_tts import WazobiaVoiceMultilingualTTS

device = "cuda" if torch.cuda.is_available() else "cpu"
model = WazobiaVoiceMultilingualTTS.from_pretrained(device)

wav = model.generate(
    "My guy don land from Abuja since morning, we dey gist about how we go "
    "reach market buy beans and fresh fish for evening chop.",
    language_id="pcm",
    audio_prompt_path="path/to/a_5_to_10_second_reference_clip.wav",
    exaggeration=0.55,
    cfg_weight=0.55,
)
ta.save("output.wav", wav, model.sr)
```

`language_id` accepts: `yo` (Yoruba), `ha` (Hausa), `ig` (Igbo), `pcm`
(Nigerian Pidgin), `en` (English) — plus the ~23 other languages inherited
from the base multilingual model. `audio_prompt_path` is a short (5–10s)
reference clip of the voice to clone; omit it to reuse whatever voice was
last prepared via `model.prepare_conditionals(...)`.

### Full parameter list

```python
model.generate(
    text,                    # str, required
    language_id,             # str, required — see SUPPORTED_LANGUAGES
    audio_prompt_path=None,  # str, path to reference audio for voice cloning
    exaggeration=0.5,        # float, emotion/expressiveness intensity
    cfg_weight=0.5,          # float, classifier-free guidance weight
    temperature=0.8,
    repetition_penalty=1.2,
    min_p=0.05,
    top_p=1.0,
)
```

### Listing supported languages

```python
from wazobiavoice_tts.mtl_tts import SUPPORTED_LANGUAGES
print(SUPPORTED_LANGUAGES)
# {'ar': 'Arabic', ..., 'yo': 'Yoruba', 'ha': 'Hausa', 'ig': 'Igbo', 'pcm': 'Nigerian Pidgin', 'en': 'English', ...}
```

### Loading from a local checkpoint instead of the Hub

```python
model = WazobiaVoiceMultilingualTTS.from_local("path/to/checkpoint_dir", device)
```

---

## Demo apps

```bash
python multilingual_app.py       # Gradio web UI, multilingual
python gradio_tts_turbo_app.py   # Gradio web UI, turbo model
python gradio_vc_app.py          # Gradio web UI, voice conversion
```

---

## About

WazobiaVoice is built and maintained by **Emmanuel Ariyo (Ememzyvisuals)**,
an independent Machine Learning and AI Engineer, under **Axiveri** — an
initiative building the African AI models that African companies, startups,
developers, and researchers can build on.

- GitHub: [Ememzyvisuals](https://github.com/Ememzyvisuals)
- Model card: [Axiveri/WazobiaVoice](https://huggingface.co/Axiveri/WazobiaVoice)
- Contact: ememzyvisuals@gmail.com

## Citation

```bibtex
@software{wazobiavoice2026,
  author = {Ariyo, Emmanuel},
  title  = {WazobiaVoice: Nigerian Multilingual Text-to-Speech},
  year   = {2026},
  url    = {https://github.com/Ememzyvisuals/wazobiavoice-TTS},
  note   = {Built under Axiveri. Fine-tuned from Chatterbox (Resemble AI).}
}
```

## Acknowledgements & License

WazobiaVoice is a fork of [Chatterbox](https://github.com/resemble-ai/chatterbox)
by Resemble AI, fine-tuned on Nigerian-language data. Used under the terms
of its MIT License — see `LICENSE` and `NOTICE.md`.
