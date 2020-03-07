#!/usr/bin/env bash

stage=0
gmm=tri3b

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

dataset=$1

gmm_dir=exp/${gmm}
ali_dir=data/${dataset}_sp/${gmm}_ali

for f in ${gmm_dir}/final.mdl; do
  if [ ! -f $f ]; then
    echo "$0: expected file $f to exist"
    exit 1
  fi
done

njobs=$(($(nproc)-1))
n_speakers_test=$(cat data/${dataset}/spk2utt| wc -l)
if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if [ $stage -le 1 ]; then
  # Although the nnet will be trained by high resolution data, we still have to
  # perturb the normal data to get the alignment _sp stands for speed-perturbed
  echo "$0: preparing directory for low-resolution speed-perturbed data (for alignment)"
  utils/data/perturb_data_dir_speed_3way.sh data/${dataset} data/${dataset}_sp
  echo "$0: making MFCC features for low-resolution speed-perturbed data"
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/${dataset}_sp || exit 1;
  steps/compute_cmvn_stats.sh data/${dataset}_sp || exit 1;
  utils/fix_data_dir.sh data/${dataset}_sp
fi

if [ $stage -le 2 ]; then
  echo "$0: aligning with the perturbed low-resolution data"
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/${dataset}_sp data/lang $gmm_dir $ali_dir || exit 1
fi