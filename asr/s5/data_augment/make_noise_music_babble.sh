#!/usr/bin/env bash

sampling_rate=16000

. utils.sh
. path.sh
. utils/parse_options.sh

musan_dir=$1
dataset=$2

musan_prep_dir=${dataset}_musan
log_info "Add Noise, Music, Speech"
log_time ./steps/data/make_musan.sh --sampling-rate $sampling_rate $musan_dir ${musan_prep_dir}

for name in speech noise music; do
  utils/data/get_utt2dur.sh $musan_prep_dir/musan_${name}
  mv $musan_prep_dir/musan_${name}/utt2dur $musan_prep_dir/musan_${name}/reco2dur
done

steps/data/augment_data_dir.py --utt-suffix "noise" --fg-interval 1 --fg-snrs "15:10:5:0" --fg-noise-dir "$musan_prep_dir/musan_noise" ${dataset} ${dataset}_noise
steps/data/augment_data_dir.py --utt-suffix "music" --bg-snrs "15:10:8:5" --num-bg-noises "1" --bg-noise-dir "$musan_prep_dir/musan_music" ${dataset} ${dataset}_music
steps/data/augment_data_dir.py --utt-suffix "babble" --bg-snrs "20:17:15:13" --num-bg-noises "3:4:5:6:7" --bg-noise-dir "$musan_prep_dir/musan_speech" ${dataset} ${dataset}_babble
utils/combine_data.sh ${dataset}_aug ${dataset}_noise ${dataset}_music ${dataset}_babble