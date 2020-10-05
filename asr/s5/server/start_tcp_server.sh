#!/usr/bin/env bash

samp_freq=16000
model_dir=/home/sylvainlg/kaldi/egs/librifrench/s5/exp/chain_online_cmn/tdnn1k_sp_online
model=$model_dir/final.mdl
graph=/home/sylvainlg/kaldi/egs/librifrench/s5/exp/chain_online_cmn/tree_sp/graph_tgsmall/HCLG.fst
words=/home/sylvainlg/kaldi/egs/librifrench/s5/exp/chain_online_cmn/tree_sp/graph_tgsmall/words.txt
online_conf=$model_dir/conf/online.conf

online2-tcp-nnet3-decode-faster \
    --samp-freq=$samp_freq \
    --frames-per-chunk=20 \
    --extra-left-context-initial=0 \
    --frame-subsampling-factor=3 \
    --config=$online_conf \
    --min-active=200 --max-active=7000 \
    --beam=15.0 --lattice-beam=6.0 \
    --acoustic-scale=1.0 \
    --port-num=5050 \
    $model $graph $words