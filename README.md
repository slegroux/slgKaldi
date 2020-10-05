[![forthebadge](https://forthebadge.com/images/badges/built-with-love.svg)](https://forthebadge.com)

[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![made-with-python](https://img.shields.io/badge/Made%20with-Python-1f425f.svg)](https://www.python.org/)
[![made-with-VSCode](https://img.shields.io/badge/Made%20for-VSCode-1f425f.svg)](https://code.visualstudio.com/)
[![Generic badge](https://img.shields.io/badge/Made%20for-Kaldi-1f425f.svg)](https://shields.io/)

# Easy Kaldi
## Description
A collection of scripts based on [Kaldi](https://github.com/kaldi-asr/kaldi) for speech recognition, diarization & language modeling
### Speech Recognition [asr](asr/README.md)
- 1. Data prep
- 2. Lexicon generation
- 3. Grammar generation (pocolm & srilm)
- 4. Feature extraction
- 5. HMM-GMM training
- 6. Data augmentation (speed, volume, reverb, music, noise, babble)
- 7. Embedding (i-vector, x-vector)
- 8. DNN training
- 9. RNNLM training
- 10. Rescoring

### Diarization [diarization](diarization/README.md)
- 1. i-vector (LIUM)
- 2. x-vector (Kaldi)

## Installation
### Dependencies
- depends on: [Kaldi](https://github.com/kaldi-asr/kaldi) & [slgasr](https://github.com/slegroux/slgasr)
- Refer to respective projects for install info

## Free Datasets
- [OpenSLR](https://www.openslr.org/resources.php)

## Pretrained models
- [kaldi-asr](http://kaldi-asr.org/models.html)  

## License
[GPL](https://www.gnu.org/licenses/gpl-3.0-standalone.html)

## Authors
(c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>
