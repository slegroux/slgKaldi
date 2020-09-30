#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>
# TODO(slg): parallelize

stage=0

. cfg/es_commonvoice.cfg

. utils.sh
. path.sh
. utils/parse_options.sh

# DATA PREP
# https://kaldi-asr.org/doc/data_prep.html

if [ $stage -eq 0 ]; then
    for dataset in ${datasets}; do
        name=$(basename $dataset .tsv)
        if [ ! -d ${data}/${name} ]; then
            ./data_prep/format_commonvoice.py ${dataset} ${data}/${name} ||exit 1
        fi
    done
fi

# L
# https://kaldi-asr.org/doc/data_prep.html#data_prep_lang

if [ $stage -eq 1 ]; then
    ./data_prep/make_L.sh --unk ${unk} --lang ${lang} ${lexicon} ${dict} ${lang_dir} || exit 1
    echo "number of non silent phones:" $(cat ${dict}/nonsilence_phones.txt|wc -l)
    echo "vocabulary size: " $(cat ${lang_dir}/words.txt|wc -l)
fi

# G
#  https://kaldi-asr.org/doc/data_prep.html#data_prep_grammar
# TODO(slg): download corpus + pocolm
if [ $stage -eq 2 ]; then
    ./data_prep/prepare_text.sh ${lm_corpus} ${lm_train} 
    # ./lm/make_srilm.sh --unk ${unk} ${lm_train} ${lm_dir}
    ./lm/make_pocolm.sh --order ${lm_order} --limit-unk-history true \
        ${lm_train} ${lm_dir}
    utils/format_lm.sh \
        ${lang_dir} ${lm_dir}/${lm_order}gram_unpruned.arpa.gz ${dict}/lexicon.txt \
        ${g_dir}
fi

# FEATURES
if [ $stage -eq 3 ]; then
    for dataset in {${train},${test},${dev}}; do
        ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config "conf/mfcc.conf" ${dataset} || exit 1
    done
fi

# HMM-GMM
if [ $stage -eq 4 ]; then
    # TODO(slg): figure out nj settings
    ./hmm/monophone_training.sh --nj ${nj_mono} --boost-silence ${boost_silence} ${train} ${lm} ${mono} || exit 1
    ./hmm/triphone_training.sh --boost-silence ${boost_silence} ${train} ${lm} ${mono}_ali ${tri1} || exit 1
    ./hmm/lda_mllt_training.sh ${train} ${lm} ${tri1}_ali ${tri2} || exit 1
    ./hmm/sat_training.sh ${train} ${lm} ${tri2}_ali ${tri3} || exit 1
    # ./utils/data/subset_data_dir.sh ${test_set} 1000 ${test_set}_1000
    ./hmm/am_testing.sh --mono false --compile_graph true ${test} ${lm} ${tri3} ${tri3}/graph || exit 1
fi

# i-vector
if [ $stage -eq 5 ]; then
    # data augment end extract hires mfcc
    ./embeddings/ivector_data_prep.sh ${train} ${lang} ${tri3} #${dataset}_sp_vp_hires #tri3_sp_ali || exit 1
    ./embeddings/ivector_training.sh --nj ${nj_ivec_extract} --online_cmvn_iextractor ${online_cmvn_iextractor} ${train}_sp_vp_hires ${tri3} ${ivec_model} || exit 1
    ./embeddings/ivector_extract.sh ${train}_sp_vp_hires ${ivec_extractor} ${train}_sp_vp_hires/ivectors || exit 1
fi

if [ $stage -eq 6 ]; then
    # implicitely align on _sp and generate align lats on _sp_vp_lats
    ./dnn/make_lang_chain.sh ${train}_sp_vp ${tri3} ${lang} ${lang_chain} ${tree}
    ./dnn/tdnnf_tedlium_s5_r3.sh ${tree} ${mdl}
    ./dnn/dnn_training.sh --train_stage ${train_stage} --num_epochs ${num_epochs} --n_gpu ${n_gpu} \
        ${train} ${lat_dir} ${ivec_data} ${tree} ${mdl}

    # utils/copy_data_dir.sh ${test_set}_1000 ${test_set}_1000_hires
    # ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${test_data}
    # ./embeddings/ivector_extract.sh ${test_data} ${ivec_extractor} ${test_data}/ivectors
    # ./dnn/dnn_testing.sh --compute_graph false ${test_data} ${lang_test} ${tree} ${graph} ${test_data}/ivectors ${mdl} ${decode_dir}

fi