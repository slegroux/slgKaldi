#!/usr/bin/env bash

sampling_rate=16000
musan_dir=/data/musan

. path.sh
. utils/parse_options.sh

dataset=$1

orig_data_dir=data/${dataset}

musan_prep_dir=${orig_data_dir}_musan
./steps/data/make_musan.sh --sampling-rate $sampling_rate $musan_dir ${musan_prep_dir}

for name in speech noise music; do
  utils/data/get_utt2dur.sh $musan_prep_dir/musan_${name}
  mv $musan_prep_dir/musan_${name}/utt2dur $musan_prep_dir/musan_${name}/reco2dur
done

# Augment with musan_noise
steps/data/augment_data_dir.py --utt-suffix "noise" --fg-interval 1 --fg-snrs "15:10:5:0" --fg-noise-dir "$musan_prep_dir/musan_noise" ${orig_data_dir} ${orig_data_dir}_noise
# Augment with musan_music
steps/data/augment_data_dir.py --utt-suffix "music" --bg-snrs "15:10:8:5" --num-bg-noises "1" --bg-noise-dir "$musan_prep_dir/musan_music" ${orig_data_dir} ${orig_data_dir}_music
# Augment with musan_speech
steps/data/augment_data_dir.py --utt-suffix "babble" --bg-snrs "20:17:15:13" --num-bg-noises "3:4:5:6:7" --bg-noise-dir "$musan_prep_dir/musan_speech" ${orig_data_dir} ${orig_data_dir}_babble

utils/combine_data.sh ${orig_data_dir}_aug ${orig_data_dir}_noise ${orig_data_dir}_music ${orig_data_dir}_babble