#!/usr/bin/env bash

. path.sh
. utils/parse_options.sh

dataset=$1

./local/make_sp.sh ${dataset}
./local/make_vp.sh ${dataset}
./local/make_rvb.sh ${dataset}
./local/make_noise_music_babble.sh ${dataset}
./utils/combine_data.sh ${dataset}_combined ${dataset}{_sp,_vp,_rvb,_aug}