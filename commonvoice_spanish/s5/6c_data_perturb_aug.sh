#!/usr/bin/env bash
stage=0

data_root=/data

. path.sh
. utils/parse_options.sh

dataset=$1
if [ $stage -le 0 ]; then
    ./local/make_sp.sh ${dataset}
fi

if [ $stage -le 1 ]; then
    ./local/make_vp.sh ${dataset}
fi

if [ $stage -le 2 ]; then
    ./local/make_rvb.sh --rir_dir ${data_root}/RIRS_NOISES ${dataset}
fi

if [ $stage -le 3 ]; then
    ./local/make_noise_music_babble.sh --musan_dir ${data_root}/musan ${dataset}
fi

if [ $stage -le 4 ]; then
    ./utils/combine_data.sh data/${dataset}_combined data/${dataset}{_sp,_vp,_rvb,_aug}
fi