#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# I: silence.csl, nonsilence.csl, lang, tri3
# O: topo, sp_ali_lats, lang_chain, tree/final.mdl


set -euo pipefail
num_leaves=3500

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1 # lores train_sp
tri3=$2
lang=$3
lang_chain=$4
tree_dir=$5

nj=$(get_njobs $dataset)


log_info "Create lang directory with chain-type topology"
# Create a version of the lang/ directory that has one state per phone in the
# topo file. [note, it really has two states.. the first one is only repeated
# once, the second one has zero or more repeats.]
if [ -d $lang_chain ]; then
  if [ $lang_chain/L.fst -nt ${lang}/L.fst ]; then
    echo "$0: $lang_chain already exists, not overwriting it; continuing"
  else
    echo "$0: $lang_chain already exists and seems to be older than data/lang..."
    echo " ... not sure what to do.  Exiting."
    exit 1;
  fi
else
  cp -r ${lang} ${lang_chain}
  silphonelist=$(cat $lang_chain/phones/silence.csl) || exit 1;
  nonsilphonelist=$(cat $lang_chain/phones/nonsilence.csl) || exit 1;
  # Use our special topology... note that later on may have to tune this
  # topology.
  log_time steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang_chain/topo
fi

if [ ! -f $dataset/feats.scp ]; then
  log_info "compute mfcc for $dataset"
  features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc.conf ${dataset}
fi

# Get the alignments as lattices (gives the chain training more freedom).
# use the same num-jobs as the alignments

log_info "Get alignments as lattices"
if [ ! -f ${tri3}_sp_ali_lats/lat.1.gz ]; then
  log_time steps/align_fmllr_lats.sh --nj ${nj} --cmd "run.pl" ${dataset} \
    ${lang} ${tri3} ${tri3}_sp_ali_lats
  rm ${tri3}_sp_ali_lats/fsts.*.gz # save space
else
  log_info "Alignments already computed"
fi


# Build a tree using our new topology.  We know we have alignments for the
# speed-perturbed data (local/nnet3/ivector_common.sh made them), so use
# those.  The num-leaves is always somewhat less than the num-leaves from
# the GMM baseline.
if [ -f $tree_dir/final.mdl ]; then
  echo "$0: $tree_dir/final.mdl already exists, refusing to overwrite it."
  exit 1;
fi

if [ ! -f ${tri3}_sp_ali/ali.1.gz ]; then
  log_info "compute sp alignemnts for tree building"
  log_time steps/align_fmllr.sh --nj $nj \
    ${dataset} ${lang} ${tri3} ${tri3}_sp_ali
fi

steps/nnet3/chain/build_tree.sh \
  --frame-subsampling-factor 3 \
  --context-opts "--context-width=2 --central-position=1" \
  --cmd "run.pl" ${num_leaves} ${dataset} \
  ${lang_chain} ${tri3}_sp_ali $tree_dir
