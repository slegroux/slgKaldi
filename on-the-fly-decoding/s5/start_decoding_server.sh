#!/usr/bin/env bash

sr=16000

chain_model_dir=exp/chain_online_cmn
online_model_dir=${chain_model_dir}/tdnn64k_sp_online
online_conf=$online_model_dir/conf/online.conf
graph=$chain_model_dir/tree_sp/graph_tgsmall/HCLG.fst
words=$chain_model_dir/tree_sp/graph_tgsmall/words.txt

. path.sh
. cmd.sh

online2-tcp-nnet3-decode-faster --samp-freq=${sr} --frames-per-chunk=20 --extra-left-context-initial=0 \
    --frame-subsampling-factor=3 --config=${online_conf} --min-active=200 --max-active=7000 \
    --beam=15.0 --lattice-beam=6.0 --acoustic-scale=1.0 --port-num=5050 ${online_model_dir}/final.mdl $graph $words