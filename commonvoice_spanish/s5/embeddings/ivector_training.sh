#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

set -euo pipefail

online_cmvn_iextractor=false
num_frames=700000
nj=6

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
tri3=$2
ivec_model=$3

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

for f in ${dataset}/feats.scp ${tri3}/final.mdl; do
  if [ ! -f $f ]; then
    echo "$0: expected file $f to exist"
    exit 1
  fi
done

log_info "Computing a subset of data to train the diagonal UBM."

# We'll use about a quarter of the data.
num_utts_total=$(wc -l <${dataset}/utt2spk)
num_utts=$[$num_utts_total/4]
utils/data/subset_data_dir.sh ${dataset} \
    $num_utts ${dataset}_subset


log_info "Compute PCA transform on sp_vp_hires $num_utts utts subset"

log_time steps/online/nnet2/get_pca_transform.sh --cmd "run.pl" \
    --splice-opts "--left-context=3 --right-context=3" \
    --max-utts 10000 --subsample 2 \
    ${dataset}_subset \
    ${ivec_model}/pca_transform

log_info "Train diagonal UBM on sp_vp_hires $num_utts utts subset"
# Use 512 Gaussians in the UBM.
nj_diag_ubm=$(get_njobs ${dataset}_subset)
log_time steps/online/nnet2/train_diag_ubm.sh --cmd "run.pl" --nj $nj_diag_ubm \
  --num-frames ${num_frames} \
  ${dataset}_subset 512 \
  ${ivec_model}/pca_transform ${ivec_model}/diag_ubm
#  --num-threads 8 \

# Train the iVector extractor.  Use all of the speed-perturbed data since iVector extractors
# can be sensitive to the amount of data.  The script defaults to an iVector dimension of
# 100.
log_info "train iVector extractor on full sp_vp_hires dataset"
log_time steps/online/nnet2/train_ivector_extractor.sh --cmd "run.pl" --nj $nj \
  --online-cmvn-iextractor $online_cmvn_iextractor \
  ${dataset} ${ivec_model}/diag_ubm \
  ${ivec_model}/extractor || exit 1;
#  --num-threads 4 --num-processes 2 \

# We extract iVectors on the speed-perturbed training data after combining
# short segments, which will be what we train the system on.  With
# --utts-per-spk-max 2, the script pairs the utterances into twos, and treats
# each of these pairs as one speaker; this gives more diversity in iVectors..
# Note that these are extracted 'online'.

# note, we don't encode the 'max2' in the name of the ivectordir even though
# that's the data we extract the ivectors from, as it's still going to be
# valid for the non-'max2' data, the utterance list is the same.
# e.g ivectors are in ${dataset}/ivectors not ${dataset}_max2/ivectors

# having a larger number of speakers is helpful for generalization, and to
# handle per-utterance decoding well (iVector starts at zero).
log_info "Pairs speaker utts"
log_time utils/data/modify_speaker_info.sh --utts-per-spk-max 2 \
  ${dataset} ${dataset}_max2

nj_extract_max2=$(get_njobs ${dataset}_max2)
log_info "Extract ivec for max2"
log_time steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj_extract_max2 \
  ${dataset}_max2 ${ivec_model}/extractor ${dataset}/ivectors
