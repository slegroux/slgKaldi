#!/usr/bin/env bash
stage=0

. path.sh
. utils/parse_options.sh

dataset=data/train500
rir_dir=/home/syl20/data/rir/RIRS_NOISES
musan_dir=/home/syl20/data/noise/musan

if [ $stage -le 0 ]; then
    # *3
    ./data_augment/make_sp.sh ${dataset}
fi

if [ $stage -le 1 ]; then
    # *1
    ./data_augment/make_vp.sh ${dataset}
fi

if [ $stage -le 2 ]; then
    # *3 (small medium noise)
    ./data_augment/make_rvb.sh ${rir_dir} ${dataset}
fi

if [ $stage -le 3 ]; then
    ./data_augment/make_noise_music_babble.sh --sampling_rate 16000 ${musan_dir} ${dataset}
fi

if [ $stage -le 4 ]; then
    # *9
    ./utils/combine_data.sh ${dataset}_combined ${dataset}{_sp,_vp,_rvb,_aug}
fi