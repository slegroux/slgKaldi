#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>
# TODO(slg): parallelize
# TODO(slg): keep kaldi logs not just echo

stage=0

. utils.sh
. path.sh
. utils/parse_options.sh

config=$1
source ${config}

# DATA PREP
# https://kaldi-asr.org/doc/data_prep.html

if [ $stage -eq 0 ]; then
    # commonvoice
    # for dataset in ${datasets}; do
    #     name=$(basename $dataset .tsv)
    #     if [ ! -d ${data}/${name} ]; then
    #         ./data_prep/format_commonvoice.py ${dataset} ${data}/${name} ||exit 1
    #         ./utils/fix_data_dir.sh ${data}/${name}
    #     fi
    # done

    # webex train

    if [ ! -f ${data}/${name}/wav.scp ]; then
        ./data_prep/format_es_webex.py ${webex_train_csv} ${webex_train_audio} ${train}
        ./utils/fix_data_dir.sh ${data}/${name}
    fi

    # webex test
    if [ ! -f ${data}/${name}/wav.scp ]; then
        ./data_prep/format_es_webex.py ${webex_tst_csv} ${webex_tst_audio} ${test}
        ./utils/fix_data_dir.sh ${data}/${name}
    fi

    # librispeech
    # log_info "Data Kaldi formatting"
    # for dataset in ${datasets}; do
    #     name=$(echo $(basename $dataset) | sed 's:-:_:g')
    #     if [ ! -d ${data}/${name} ]; then
    #         log_time ./data_prep/format_librispeech.py "${dataset}" "${data}/${name}"
    #         ./utils/fix_data_dir.sh ${data}/${name}
    #     fi
    # done
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
    if [ ! -d ${lm_dir} ]; then
        mkdir -p ${lm_dir}
    fi
    ./data_prep/prepare_text.sh ${corpus_train} ${lm_train} || exit 1
    ./data_prep/prepare_text.sh ${corpus_dev} ${lm_dev} || exit 1

    # ./lm/make_srilm.sh --unk ${unk} ${lm_train} ${lm_dir}
    # utils/format_lm.sh \
    #     ${lang_dir} ${lm_dir}/${lm_order}-gram-srilm.arpa.gz ${dict}/lexicon.txt \
    #     ${lm}

    for order in ${lm_order}; do
        ./lm/make_pocolm.sh --order ${order} --limit_unk_history ${limit_unk_history} \
            ${lm_train} ${lm_dev} ${lm_dir} || exit 1

        log_info "Convert LM to FST"
        utils/format_lm.sh \
            ${lang_dir} ${lm_dir}/${order}gram_unpruned.arpa.gz ${dict}/lexicon.txt \
            ${lang_dir}_$(basename ${train})_${order}g || exit 1
    done
fi

# FEATURES
if [ $stage -eq 3 ]; then
    for dataset in {${train},${test},${dev}}; do
        if [ ! -f ${dataset}/feats.scp ]; then
            ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config "conf/mfcc.conf" ${dataset} || exit 1
        else
            log_info "feats already computed"
        fi
    done
fi

# HMM-GMM
if [ $stage -eq 4 ]; then
    # TODO(slg): figure out nj settings
    ./hmm/monophone_training.sh --nj ${nj_mono} --boost-silence ${boost_silence} --subset ${subset} ${train} ${lm} ${mono} || exit 1
    ./hmm/triphone_training.sh --boost-silence ${boost_silence} ${train} ${lm} ${mono}_ali ${tri1} || exit 1
    ./hmm/lda_mllt_training.sh ${train} ${lm} ${tri1}_ali ${tri2} || exit 1
    ./hmm/sat_training.sh ${train} ${lm} ${tri2}_ali ${tri3} || exit 1
fi

# HMM testing
if [ $stage -eq 41 ]; then
    if [ ! -d ${test}_1000 ]; then
        ./utils/data/subset_data_dir.sh ${test} 1000 ${test}_1000
    fi
    ./hmm/am_testing.sh --mono false --compile_graph true ${test}_1000 ${lm} ${tri3} ${tri3}/graph_test_1000 || exit 1
fi


# IVECTOR TRAINING
if [ $stage -eq 5 ]; then
    # data augment end extract hires mfcc
    # input: ${dataset} => output: ${dataset]_sp tri3_sp_ali ${dataset}_sp_vp_hires
    ./embeddings/ivector_data_prep.sh ${train} ${lang_dir} ${tri3} || exit 1
    # input: hires (sp_vp_hires) data => output exp/ivector_extractor and ${dataset}_sp_vp_hires/ivector_data
    ./embeddings/ivector_training.sh \
        --nj ${nj_ivec_extract} \
        --num_processes ${n_processes} --num_threads ${n_threads} \
        --online_cmvn_iextractor ${online_cmvn_iextractor} --subset_factor ${subset_factor} \
        ${train}_sp_vp_hires ${tri3} ${ivec_model} || exit 1
    # echo "skip i-vector training"
fi

# IVECTOR EXTRACTION
if [ $stage -eq 6 ]; then
    # TODO(slg): why do we pertub ? should it just be hires and that's it for computing i-vector and decoding?
    if [ ! -d ${train}_sp_vp_hires ]; then
        ./data_augment/make_sp_vp_hires.sh ${train} # only needed if using pre-trained i-vector extractor. else stage 5 will provide it
    fi
    ./embeddings/ivector_extract.sh ${train}_sp_vp_hires ${ivec_extractor} ${train}_sp_vp_hires/ivectors || exit 1
fi

# DNN TRAINING
if [ $stage -eq 7 ]; then
    # use lores (_sp) implicitely align on _sp and generate align lats on _sp_lats
    ./dnn/make_lang_chain.sh ${train}_sp ${tri3} ${lang_dir} ${lang_chain} ${tree}
    # build network architecture
    ./dnn/${dnn_architecture}.sh ${tree} ${mdl}
    # train on hires (_sp_vp_hires)
    ./dnn/dnn_training.sh --train_stage ${train_stage} --n_gpu ${n_gpu} --num_epochs ${num_epochs} --remove_egs ${remove_egs} \
        ${train}_sp_vp_hires ${lat_dir} ${ivec_data} ${tree} ${mdl}
    ./steps/nnet3/report/generate_plots.py --is-chain true ${mdl} ${mdl}/report/
    # scp syl20@dx05:${mdl}/report/log_probability_output.pdf .
    steps/info/chain_dir_info.pl ${mdl}
fi

# DNN TESTING
if [ $stage -eq 71 ]; then
    # extract feats for test set
    utils/copy_data_dir.sh ${test} ${test}_hires
    ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${test}_hires
    ./embeddings/ivector_extract.sh ${test}_hires ${ivec_extractor} ${test}_hires/ivectors
    # decode folder: decode_"lm_name"_"test_data"
    if [ -d ${graph} ]; then
        ./dnn/dnn_testing.sh --compute_graph false ${test}_hires ${lang_test} ${tree} ${graph} ${test}_hires/ivectors ${mdl} ${decode_test_name}
    else
        ./dnn/dnn_testing.sh --compute_graph true ${test}_hires ${lang_test} ${tree} ${graph} ${test}_hires/ivectors ${mdl} ${decode_test_name}
    fi
fi

# RESCORING
if [ $stage -eq 8 ]; then
    ./rescoring/ngram_rescoring.sh ${old_lm} ${new_lm} ${test}_hires ${mdl}/${decode_test_name}
fi

# RNNLM TRAINING
if [ $stage -eq 9 ]; then
    if [ ! -d ${rnnlm_data} ]; then
        mkdir -p ${rnnlm_data}
        for text in ${lm_dir}/{train,dev}.txt; do
            cp ${text} ${rnnlm_data}
        done
    fi

    ./lm/train_lstm_tdnn_lm.sh \
        --stage ${rnn_stage} \
        --train_stage ${rnn_train_stage} \
        --n_gpu ${rnn_gpu} --epochs ${rnn_epochs} \
        --embedding_dim ${rnnlm_embedding_dim} \
        --lstm_rpd ${lstm_rpd} \
        --lstm_nrpd ${lstm_nrpd} \
        ${rnnlm_dir} ${wordlist} ${rnnlm_data}
fi

# RNNLM TESTING
if [ $stage -eq 91 ]; then
    ./rescoring/rescore_pruned.sh --ngram-order ${rescore_ngram_order} ${lm} ${rnnlm_dir} ${rnnlm_test} ${decode_og} ${decode_rnnlm}
fi

# ONLINE DECODING
if [ $stage -eq 10 ]; then
    if [ ! -d ${mdl}_online ]; then
        steps/online/nnet3/prepare_online_decoding.sh \
            --mfcc-config conf/mfcc_hires.conf \
            ${lang_chain} ${ivec_extractor} ${mdl} ${mdl}_online
    fi

    nj=$(get_njobs $test)
    steps/online/nnet3/decode.sh \
          --acwt 1.0 --post-decode-acwt 10.0 \
          --nj $nj --cmd "run.pl" \
          ${graph} ${test} ${online_decode_dir}
    log_wer ${online_decode_dir}
fi

# UPLOAD MODEL
if [ $stage -eq 101 ]; then
    ./models/archive_model.sh ${online_mdl} ${graph} ${archive_name}
    ./models/upload_model_to_s3.sh ${lang} models/${archive_name}
fi

# RUN SERVER
if [ $stage -eq 11 ]; then
    server/start_tcp_server.sh \
        --samp_freq ${samp_freq} \
        --online_conf ${online_conf} \
        --port_num ${port_num} \
        ${mdl}_online ${graph} ${wordlist}
fi

# TEST SERVER
if [ $stage -eq 12 ]; then
    ./server/test_tcp_server.sh ${test_audio}
    echo $test_transcript
fi
