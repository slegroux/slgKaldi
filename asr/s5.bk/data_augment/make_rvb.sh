#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

sampling_rate=16000

. utils.sh
. path.sh
. utils/parse_options.sh

rir_dir=$1
orig_data_dir=$2

log_info "Reverb"
### add to the data
small_rooms=${rir_dir}/simulated_rirs/smallroom/rir_list
medium_rooms=${rir_dir}/simulated_rirs/mediumroom/rir_list
noises=${rir_dir}/pointsource_noises/noise_list

# dataset lists expect RIR path to be current dir
for list in {$small_rooms,$medium_rooms,$noises}; do
  sed "s:RIRS_NOISES:${rir_dir}:g" $list > ${list}_
done

rvb_opts=()
rvb_opts+=(--rir-set-parameters "0.5, ${small_rooms}_")
rvb_opts+=(--rir-set-parameters "0.5, ${medium_rooms}_")
rvb_opts+=(--noise-set-parameters ${noises}_)

num_reps=3
snrs="20:10:15:5:0"
foreground_snrs="20:10:15:5:0"
background_snrs="20:10:15:5:0"
log_time python steps/data/reverberate_data_dir.py \
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
  ${orig_data_dir} ${orig_data_dir}_rvb