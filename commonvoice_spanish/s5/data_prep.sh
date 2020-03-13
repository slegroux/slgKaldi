#!/usr/bin/env bash

data_root=$DATA

. path.sh
. utils/parse_options.sh

dataset=$1

# ./local/make_sp.sh ${dataset}
# ./local/make_vp.sh ${dataset}
# ./local/make_rvb.sh --rir_dir ${data_root}/RIRS_NOISES ${dataset}
# ./local/make_noise_music_babble.sh --musan_dir ${data_root}/musan ${dataset}
./utils/combine_data.sh data/${dataset}_combined data/${dataset}{_sp,_vp,_rvb,_aug}