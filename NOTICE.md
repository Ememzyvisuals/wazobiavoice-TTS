This project is a fork of [Chatterbox](https://github.com/resemble-ai/chatterbox)
by Resemble AI, used under the terms of its MIT License (see `LICENSE`).

Modifications by Axiveri:
- Package renamed from `chatterbox` to `wazobiavoice_tts`; public classes
  renamed accordingly (`ChatterboxTTS` -> `WazobiaVoiceTTS`, etc.)
- Default model weights repointed from `ResembleAI/chatterbox` to
  `Axiveri/WazobiaVoice`
- Base model fine-tuned via LoRA on Nigerian-language data (Yoruba, Hausa,
  Igbo, Nigerian Pidgin, Nigerian-accented English) — see the WazobiaVoice
  model card for training details

This NOTICE is kept for internal record-keeping and license compliance. It is
not required to be surfaced in end-user-facing product UI.
