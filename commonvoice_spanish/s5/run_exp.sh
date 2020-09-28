#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

stage=0

. utils.sh
. path.sh
. utils/parse_options.sh

# conda activate slgasr
# today=$(date +'%Y%m%d')
today=20200927
data=data/${today}
exp=exp/${today}

if [ $stage -le 0 ]; then
    # DATA
    # TODO(slg): download data
    cv_root=/home/syl20/data/es/commonvoice
    for dataset in ${cv_root}/{train,test,dev}.tsv; do
        name=$(basename $dataset .tsv)
        ./data_prep/format_commonvoice.py ${dataset} ${data}/${name} ||exit 1
    done

    # L
    # TODO(slg): letter-based lexicon (santiago)
    lexicon="santiago.txt"
    dict=${data}/dict
    lang=${data}/lang
    ./data_prep/make_L.sh ${lexicon} ${dict} ${lang} || exit 1

    # G
    # TODO(slg): download corpus + pocolm
    lm_corpus="OpenSubtitles.en-es.es"
    lm_dir=${data}/lm
    ./data_prep/make_G.sh ${lm_corpus} ${lang}/words.txt ${dict} ${lang} ${lm_dir} || exit 1
fi

if [ $stage -le 1 ]; then
    for dataset in ${data}/{train,test,dev}; do
        ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config "conf/mfcc.conf" ${dataset} || exit 1
    done
fi

if [ $stage -le 2 ]; then
    train_set=${data}/train
    test_set=${data}/test
    dev_set=${data}/dev
    lang_train=${data}/lang
    lang_test=${data}/lang_test
    mono=${exp}/mono
    tri1=${exp}/tri1
    tri2=${exp}/tri2
    tri3=${exp}/tri3

    # OPTIONAL: some utterances can be blacklisted
    # filter_from_list ${data}/train/wav.scp ${data}/train/blacklist.txt

    ./hmm/monophone_training.sh --nj 100 --boost-silence 1.0 --subset 5000 ${train_set} ${lang_train} ${mono}
    ./hmm/triphone_training.sh --nj 100 --boost-silence 1.0 ${train_set} ${lang_train} ${mono}_ali ${tri1} || exit 1
    ./hmm/lda_mllt_training.sh --nj 100 ${train_set} ${lang_train} ${tri1}_ali ${tri2} || exit 1
    ./hmm/sat_training.sh --nj 100 ${train_set} ${lang_train} ${tri2}_ali ${tri3} || exit 1
    ./utils/data/subset_data_dir.sh ${test_set} 1000 ${test_set}_1000
    ./hmm/am_testing.sh --mono false --compile_graph true ${test_set}_1000 ${lang_test} ${tri3} ${tri3}/graph || exit 1

fi

# if [ $stage -le 3 ]; then
#     rir_dir=/home/syl20/data/rir/RIRS_NOISES
#     musan_dir=/home/syl20/data/noise/musan
#     train_set=${data}/train
#     ./data_augment/make_sp.sh ${train_set} || exit 1
#     ./data_augment/make_vp.sh ${train_set} || exit 1
#     ./data_augment/make_rvb.sh ${rir_dir} ${train_set} || exit 1
#     ./data_augment/make_noise_music_babble.sh --sampling_rate 16000 ${musan_dir} ${train_set} || exit 1
#     ./utils/combine_data.sh ${train_set}_combined ${train_set}{_sp,_vp,_rvb,_aug} || exit 1
# fi

if [ $stage -le 4 ]; then
    dataset=${data}/train
    lang=${data}/lang
    tri3=${exp}/tri3
    online_cmvn_iextractor=false
    ivec_model=${exp}/ivector_mdl
    ivec_extractor=${ivec_model}/extractor
    nj=6 #c.f. ivec train script (nj*threads*)
    ./embeddings/ivector_data_prep.sh ${dataset} ${lang} ${tri3} #${dataset}_sp_vp_hires #tri3_500_sp_ali || exit 1
    ./embeddings/ivector_training.sh --nj ${nj} --online_cmvn_iextractor ${online_cmvn_iextractor} ${dataset}_sp_vp_hires ${tri3} ${ivec_model} || exit 1
    ./embeddings/ivector_extract.sh ${dataset}_sp_vp_hires ${ivec_extractor} ${dataset}_sp_vp_hires/ivectors || exit 1
fi

if [ $stage -le 5 ]; then
    # basic data
    dataset=${data}/train

    # lang
    lang=${data}/lang
    lang_test=${data}/lang_test
    lang_chain=${data}/lang_chain
    # am
    tri3=${exp}/tri3
    # ivectors
    train_data=${dataset}_sp_vp_hires
    ivector_data=${train_data}/ivectors

    lat_dir=${tri3}_sp_vp_ali_lats
    ivec_model=${exp}/ivector_mdl
    ivec_extractor=${ivec_model}/extractor
    # dnn-mdl
    tree=${exp}/chain/tree #TODO(sylvain): change to chain2
    graph=${exp}/chain/tree/graph_tgsmall
    mdl=${exp}/chain/tdnnf_tedlium
    # training
    train_stage=-10
    num_epochs=5
    n_gpu=8

    # implicitely align on train_500_sp and generate align lats on sp_vp_lats
    # ./dnn/make_lang_chain.sh ${dataset}_sp_vp ${tri3} ${lang} ${lang_chain} ${tree}
    # ./dnn/tdnnf_tedlium_s5_r3.sh ${tree} ${mdl}
    # ./dnn/dnn_training.sh --train_stage ${train_stage} --num_epochs $num_epochs --n_gpu $n_gpu \
    #     ${train_data} ${lat_dir} ${ivector_data} ${tree} ${mdl}

    test_set=${data}/test
    test_data=${test_set}_1000_hires
    decode_dir=decode_1000_tg # needs to be a subset of model dir
    # utils/copy_data_dir.sh ${test_set}_1000 ${test_set}_1000_hires
    # ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${test_data}
    # ./embeddings/ivector_extract.sh ${test_data} ${ivec_extractor} ${test_data}/ivectors
    ./dnn/dnn_testing.sh --compute_graph false ${test_data} ${lang_test} ${tree} ${graph} ${test_data}/ivectors ${mdl} ${decode_dir}

fi