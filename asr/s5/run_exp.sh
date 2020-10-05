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
    # ./data_prep/prepare_text.sh ${corpus_train} ${lm_train}
    # ./data_prep/prepare_text.sh ${corpus_dev} ${lm_dev}

    # ./lm/make_srilm.sh --unk ${unk} ${lm_train} ${lm_dir}
    ./lm/make_pocolm.sh --order ${lm_order} --limit_unk_history ${limit_unk_history} \
        ${lm_train} ${lm_dev} ${lm_dir}
    utils/format_lm.sh \
        ${lang_dir} ${lm_dir}/${lm_order}gram_unpruned.arpa.gz ${dict}/lexicon.txt \
        ${lm}
fi

# FEATURES
if [ $stage -le 3 ]; then
    for dataset in {${train},${test},${dev}}; do
        ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config "conf/mfcc.conf" ${dataset} || exit 1
    done
fi

# HMM-GMM
if [ $stage -le 4 ]; then
    # TODO(slg): figure out nj settings
    ./hmm/monophone_training.sh --nj ${nj_mono} --boost-silence ${boost_silence} --subset ${subset} ${train} ${lm} ${mono} || exit 1
    ./hmm/triphone_training.sh --boost-silence ${boost_silence} ${train} ${lm} ${mono}_ali ${tri1} || exit 1
    ./hmm/lda_mllt_training.sh ${train} ${lm} ${tri1}_ali ${tri2} || exit 1
    ./hmm/sat_training.sh ${train} ${lm} ${tri2}_ali ${tri3} || exit 1
    # ./utils/data/subset_data_dir.sh ${test} 1000 ${test}_1000
    # ./hmm/am_testing.sh --mono false --compile_graph true ${test}_1000 ${lm} ${tri3} ${tri3}/graph_test_1000 || exit 1
fi

# i-vector training & extract
if [ $stage -le 5 ]; then
    # data augment end extract hires mfcc
    # input: ${dataset} => output: ${dataset]_sp tri3_sp_ali ${dataset}_sp_vp_hires
    ./embeddings/ivector_data_prep.sh ${train} ${lang_dir} ${tri3}
    # input: hires (sp_vp_hires) data => output exp/ivector_extractor and ${dataset}_sp_vp_hires/ivector_data
    ./embeddings/ivector_training.sh --nj ${nj_ivec_extract} --online_cmvn_iextractor ${online_cmvn_iextractor} ${train}_sp_vp_hires ${tri3} ${ivec_model} || exit 1
    # echo "skip i-vector training"
fi

# pre-trained i-vectors
if [ $stage -le 6 ]; then
    ./data_augment/make_sp_vp_hires.sh ${train} # only needed if using pre-trained i-vector extractor. else stage 5 will provide it
    ./embeddings/ivector_extract.sh ${train}_sp_vp_hires ${ivec_extractor} ${train}_sp_vp_hires/ivectors || exit 1
fi

if [ $stage -le 7 ]; then
    # use lores (_sp) implicitely align on _sp and generate align lats on _sp_lats
    # ./dnn/make_lang_chain.sh ${train}_sp ${tri3} ${lang_dir} ${lang_chain} ${tree}
    # ./dnn/tdnnf_tedlium_s5_r3.sh ${tree} ${mdl}
    # train on hires (_sp_vp_hires)
    ./dnn/dnn_training.sh --train_stage ${train_stage} --n_gpu ${n_gpu} --num_epochs ${num_epochs} --remove_egs ${remove_egs} \
        ${train}_sp_vp_hires ${lat_dir} ${ivec_data} ${tree} ${mdl}
    # ./dnn/plot_error_curve.py ${mdl}/accuracy.report
fi

if [ $stage -le 8 ]; then
    # extract feats for test set
    utils/copy_data_dir.sh ${test} ${test}_hires
    ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${test}_hires
    ./embeddings/ivector_extract.sh ${test}_hires ${ivec_extractor} ${test}_hires/ivectors
    # decode folder: decode_"lm_name"_"test_data"
    ./dnn/dnn_testing.sh --compute_graph true ${test}_hires ${lang_test} ${tree} ${graph} ${test}_hires/ivectors ${mdl} ${decode_test_name}
    ./dnn/dnn_testing.sh --compute_graph false ${test}_hires ${lang_test} ${tree} ${graph} ${test}_hires/ivectors ${mdl} ${decode_test_name}
fi

if [ $stage -le 9 ]; then
    if [ ! -d ${rnnlm_data} ]; then
        mkdir -p ${rnnlm_data}
    fi
    for text in ${lm_dir}/{train,dev}.txt; do
        cp ${text} ${rnnlm_data}
    done

    ./lm/train_lstm_tdnn_lm.sh --stage ${rnn_stage} --train_stage ${rnn_train_stage} \
        --n_gpu ${rnn_gpu} --epochs ${rnn_epochs} \
        ${rnnlm_dir} ${wordlist} ${rnnlm_data}
fi

if [ $stage -le 10 ]; then
    ./rescoring/rescore_pruned.sh --ngram-order ${rescore_ngram_order} ${lm} ${rnnlm_dir} ${rnnlm_test} ${decode_og} ${decode_rnnlm}
fi

if [ $stage -le 11 ]; then
    ./steps/nnet3/report/generate_plots.py --is-chain true ${mdl} ${mdl}/report/
    # copy report locally
    # scp syl20@172.21.150.75:/home/syl20/kaldi-gc/kaldi_egs/commonvoice_spanish/s5/experiments/es/commonvoice/exp/chain/tdnnf_tedlium/report/{log_probability_output,log_probability_output-xent}.pdf .
fi
