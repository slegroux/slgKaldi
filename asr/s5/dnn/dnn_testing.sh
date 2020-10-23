#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>


compute_graph=true

. utils.sh
. path.sh
. utils/parse_options.sh

test_set=$1
# tree_dir=exp/chain/tree_train
lang=$2
tree_dir=$3
graph_dir=$4
ivector_data=$5
mdl=$6
decode_dir=$7

nj=$(get_njobs $test_set)

if $compute_graph; then
  # Note: it's not important to give mkgraph.sh the lang directory with the
  # matched topology (since it gets the topology file from the model).
  log_info "make graph"
  log_time utils/mkgraph.sh \
    --self-loop-scale 1.0 $lang \
    ${tree_dir} ${graph_dir}
fi

rm $mdl/.error 2>/dev/null || true

#Decoder
log_info "dnn decoding"
log_time steps/nnet3/decode.sh \
    --acwt 1.0 --post-decode-acwt 10.0 \
    --nj $nj --cmd "run.pl" \
    --online-ivector-dir $ivector_data \
    ${graph_dir} ${test_set} ${mdl}/${decode_dir}

log_wer ${mdl}/${decode_dir}


# exit 1
# if [$stage -le 17 ]; then
#   steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
#   data/${lang}_{tgsmall,tglarge} \
#   data/${test_set}_hires ${dir}/decode_{tgsmall,tglarge}_${test_set} || exit 1
  
#   echo "large lm rescoring" | tee -a WER.txt
#   for x in ${dir}/decode_tglarge_${data}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done | tee -a WER.txt
# fi

# Not testing the 'looped' decoding separately, because for
# TDNN systems it would give exactly the same results as the
# normal decoding.


