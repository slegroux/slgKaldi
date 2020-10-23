#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

samp_freq=16000
online_conf=conf/online.conf
port_num=5050
# model=$model_dir/final.mdl
# graph=/home/sylvainlg/kaldi/egs/librifrench/s5/exp/chain_online_cmn/tree_sp/graph_tgsmall/HCLG.fst
# words=/home/sylvainlg/kaldi/egs/librifrench/s5/exp/chain_online_cmn/tree_sp/graph_tgsmall/words.txt

. utils.sh
. path.sh
. utils/parse_options.sh

model=$1
graph=$2
words=$3

online2-tcp-nnet3-decode-faster \
    --samp-freq=${samp_freq} \
    --frames-per-chunk=20 \
    --extra-left-context-initial=0 \
    --frame-subsampling-factor=3 \
    --config=${online_conf} \
    --min-active=200 --max-active=7000 \
    --beam=15.0 --lattice-beam=6.0 \
    --acoustic-scale=1.0 \
    --port-num=${port_num} \
    $model/final.mdl $graph/HCLG.fst $words