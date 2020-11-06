#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

limit_unk_history=true
conf=

. utils.sh
. path.sh
. utils/parse_options.sh

corpus_train=$1
corpus_dev=$2
lang_dir=$3
lexicon=$4
lm_dir=$5

if [ ! -z $conf ]; then
    source ${conf}
fi

if [ ! -d ${lm_dir} ]; then
        mkdir -p ${lm_dir}
fi

lm_train=${lm_dir}/train.txt
lm_dev=${lm_dir}/dev.txt

./data_prep/prepare_text.sh ${corpus_train} ${lm_train} || exit 1
./data_prep/prepare_text.sh ${corpus_dev} ${lm_dev} || exit 1

# ./lm/make_srilm.sh --unk ${unk} ${lm_train} ${lm_dir}
# utils/format_lm.sh \
#     ${lang_dir} ${lm_dir}/${lm_order}-gram-srilm.arpa.gz ${dict}/lexicon.txt \
#     ${lm}

train_name=$(basename $(dirname ${corpus_train}))
for order in {3..5}; do
    log_time ./lm/make_pocolm.sh --order ${order} --limit_unk_history ${limit_unk_history} \
        ${lm_train} ${lm_dev} ${lm_dir} || exit 1

    log_info "Convert LM to FST"
    log_time utils/format_lm.sh \
        ${lang_dir} ${lm_dir}/${order}gram_unpruned.arpa.gz ${lexicon} \
        ${lang_dir}_${train_name}_${order}g || exit 1
done