#!/usr/bin/env bash

rir_dir=/data/RIRS_NOISES
sampling_rate=16000

. cmd.sh
. path.sh
. utils/parse_options.sh

orig_data_dir=$1

### add to the data
rvb_opts=()
rvb_opts+=(--rir-set-parameters "0.5, ${rir_dir}/simulated_rirs/smallroom/rir_list")
rvb_opts+=(--rir-set-parameters "0.5, ${rir_dir}/simulated_rirs/mediumroom/rir_list")
rvb_opts+=(--noise-set-parameters ${rir_dir}/pointsource_noises/noise_list)

num_reps=3
snrs="20:10:15:5:0"
foreground_snrs="20:10:15:5:0"
background_snrs="20:10:15:5:0"
python steps/data/reverberate_data_dir.py \
  "${rvb_opts[@]}" \
  --prefix "rev" \
  --foreground-snrs $foreground_snrs \
  --background-snrs $background_snrs \
  --speech-rvb-probability 1 \
  --pointsource-noise-addition-probability 1 \
  --isotropic-noise-addition-probability 1 \
  --num-replications $num_reps \
  --max-noises-per-minute 1 \
  --source-sampling-rate $sampling_rate \
  data/${orig_data_dir} data/${orig_data_dir}_rvb