#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

cv_tsv_set=/home/syl20/data/es/commonvoice/test.tsv
kaldi_data=/tmp/test3
lexicon='santiago.txt'
dict=data/dict
lang=data/lang
lm_corpus='OpenSubtitles.en-es.es'
lm_dir=/tmp/lm

./data_prep/format_commonvoice.py ${cv_tsv_set} ${kaldi_data}
# ./data_prep/make_L.sh ${lexicon} ${dict} ${lang}
# ./data_prep/make_G.sh ${lm_corpus} ${lang}/words.txt ${dict} ${lang} ${lm_dir}


