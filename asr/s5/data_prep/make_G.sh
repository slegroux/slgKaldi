#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# remove punctuation and filter OOVs

unk="<UNK>"

. utils.sh
. path.sh
. utils/parse_options.sh

corpus=$1
words=$2
dict=$3
lang=$4
lm_dir=$5


if [ ! -d ${lm_dir} ]; then
    mkdir -p ${lm_dir}
fi

# get rid of punc and keep segments with only 8<seq<16 words
./data_prep/subs_prepare_data.pl ${corpus} ${words} ${lm_dir}

# generate trigram of in_vocabulary text
./data_prep/prepare_lm.sh --unk ${unk} ${lm_dir}/in_vocabulary.txt ${lm_dir}

# generate language model G.fst
utils/format_lm.sh \
    ${lang} ${lm_dir}/trigram.arpa.gz ${dict}/lexicon.txt \
    ${lang}_test