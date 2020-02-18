#!/bin/bash

# begin configuration section
data='/home/workfit/Sylvain/Data/Librifrench' # Set this to directory where you put the data
adapt=false # Set this to true if you want to make the data as the vocabulary file,
	    # example: dès que (original text) => dès_que (vocabulary word)
liaison=true # Set this to true if you want to makes lexicon while taking into account liaison for French language
njobs=12
stage=0

# end configuration section
. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)


if [ $stage == 0 ]; then
  echo "Preparing data as Kaldi data directories"
  for part in train test; do
    local/data_prep.sh --apply_adaptation $adapt $data/$part data/$part
  done
fi


if [ $stage == 1 ]; then
  ## Optional G2P training scripts.
  #local/g2p/train_g2p.sh lexicon conf
  echo "Preparing dictionary"
  local/dic_prep.sh lexicon conf/model-2
fi


if [ $stage == 2 ]; then
  echo "Preparing language model"
  local/lm_prep.sh --order 3 --lm_system IRSTLM
  local/lm_prep.sh --order 3 --lm_system SRILM
  ## Optional Perplexity of the built models
  # local/compute_perplexity.sh --order 3 --text data/test test IRSTLM
  # local/compute_perplexity.sh --order 3 --text data/test test SRILM
fi


if [ $stage == 3 ]; then
  echo "Prepare data/lang and data/local/lang directories"
  [ $liaison == false ] && echo "No liaison is applied" && \
  utils/prepare_lang.sh --position-dependent-phones true data/local/dict "!SIL" data/local/lang data/lang
  [ $liaison == true ] && echo "Liaison is applied in the creation of lang directories" && \
  local/language_liaison/prepare_lang_liaison.sh --sil-prob 0.3 data/local/dict "!SIL" data/local/lang data/lang
  [ ! $liaison == true ] && [ ! $liaison == false ] && echo "verify the value of the variable liaison" && exit 1
fi


if [ $stage == 4 ]; then
  echo "Prepare G.fst and data/{train,dev,test} directories"
  local/format_lm.sh --liaison $liaison
fi


if [ $stage == 5 ]; then
  echo ============================================================================
  echo " MFCC extraction "
  echo ============================================================================

  mfccdir=mfcc
  for x in train test; do
    steps/make_mfcc.sh --nj $njobs data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    utils/fix_data_dir.sh data/$x
  done
  
  utils/subset_data_dir.sh data/train 4000 data/train_4k
fi


if [ $stage == 51 ]; then
  echo ============================================================================
  echo " PLP extraction "
  echo ============================================================================

  plpdir=plp
  for x in train test; do
    steps/make_plp.sh --nj $njobs data/$x exp/make_plp/$x $plpdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_plp/$x $plpdir || exit 1;
  done
  utils/subset_data_dir.sh data/train 4000 data/train_4k
fi


if [ $stage == 6 ]; then
  echo ============================================================================
  echo " MonoPhone Training & Decoding "
  echo ============================================================================

  #Train monophone model
  time steps/train_mono.sh \
    --nj $njobs \
    --config conf/monophone.conf \
    data/train_4k data/lang exp/mono

  #Decoder
  for lm in IRSTLM SRILM; do
    time utils/mkgraph.sh --mono data/lang_test_$lm exp/mono exp/mono/graph_$lm
    
    time steps/decode.sh \
      --config conf/decode.config \
      --nj $n_speakers_test \
      exp/mono/graph_$lm data/test exp/mono/decode_test_$lm
  done
  echo "Monophone training" | tee -a WER.txt
  cat conf/monophone.conf | tee -a WER.txt
  for x in exp/mono/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh |tee -a WER.txt
  done

  #Align the train data using mono-phone model
  steps/align_si.sh --nj $njobs data/train data/lang exp/mono exp/mono_ali
fi


if [ $stage == 7 ]; then
  echo ============================================================================
  echo " tri1 : TriPhone with delta delta-delta features Training & Decoding      "
  echo ============================================================================

  #Train Deltas + Delta-Deltas model based on mono_ali
  steps/train_deltas.sh 3000 40000 data/train data/lang exp/mono_ali exp/tri1

  #Decoder
  for lm in IRSTLM SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/tri1 exp/tri1/graph_$lm
    steps/decode.sh --config conf/decode.config --nj $n_speakers_test exp/tri1/graph_$lm data/test exp/tri1/decode_test_$lm
  done
  for x in exp/tri1/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
  #Align the train data using tri1 model
  steps/align_si.sh --nj $njobs data/train data/lang exp/tri1 exp/tri1_ali
fi


if [ $stage == 8 ]; then
  echo ============================================================================
  echo " tri2b : LDA + MLLT Training & Decoding / Speaker Adaptation"
  echo ============================================================================
  
  #Train LDA + MLLT model based on tri1_ali
  steps/train_lda_mllt.sh --splice-opts "--left-context=3 --right-context=3" 4000 60000 data/train data/lang exp/tri1_ali exp/tri2b

  #Decoder
  for lm in IRSTLM SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/tri2b exp/tri2b/graph_$lm
    steps/decode.sh --config conf/decode.config --nj $n_speakers_test exp/tri2b/graph_$lm data/test exp/tri2b/decode_test_$lm
  done
  for x in exp/tri2b/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
  steps/align_si.sh --nj $njobs data/train data/lang exp/tri2b exp/tri2b_ali
fi


if [ $stage == 9 ]; then
  echo ============================================================================
  echo " tri3b : LDA+MLLT+SAT Training & Decoding "
  echo ============================================================================
  
  #Train GMM SAT model based on Tri2b_ali
  steps/train_sat.sh 4000 60000 data/train data/lang exp/tri2b_ali exp/tri3b

  #Decoder
  for lm in IRSTLM SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/tri3b exp/tri3b/graph_$lm
    steps/decode_fmllr.sh --config conf/decode.config --nj $n_speakers_test exp/tri3b/graph_$lm data/test exp/tri3b/decode_test_$lm
  done
  for x in exp/tri3b/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
  #Align the train data using tri3b model
  steps/align_fmllr.sh --nj $njobs data/train data/lang exp/tri3b exp/tri3b_ali
  steps/align_fmllr.sh --nj $n_speakers_test data/test data/lang exp/tri3b exp/tri3b_ali_test
fi


if [ $stage == 10 ]; then
  echo ============================================================================
  echo " SGMM : SGMM Training & Decoding "
  echo ============================================================================
  

  #Train SGMM model based on the GMM SAT model
  steps/train_ubm.sh 400 data/train data/lang exp/tri4a_ali exp/ubm_400
  steps/train_sgmm2.sh 8000 9000 data/train data/lang exp/tri4a_ali exp/ubm_400/final.ubm exp/sgmm2

  #Decoder
  for lm in IRSTLM SRILM; do
  utils/mkgraph.sh data/lang_test_$lm exp/sgmm2 exp/sgmm2/graph_$lm
  steps/decode_sgmm2.sh --config conf/decode.config --nj $njobs --transform-dir exp/tri4a/decode_test_$lm \
    exp/sgmm2/graph_$lm data/test exp/sgmm2/decode_test_$lm
  done
  for x in exp/sgmm2/decode_*; do
  [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
fi


if [ $stage == 11 ]; then
  echo ============================================================================
  echo "                    nnet2 DNN Training & Decoding                        	"
  echo ============================================================================
  train_stage=-10
  parallel_opts="--gpu 1"
  num_threads=1
  minibatch_size=512
  l=5
  dir=exp/nnet2/pnorm/nnet2_${l}layers

  if [ ! -f $dir/final.mdl ]; then
    steps/nnet2/train_pnorm_fast.sh --stage $train_stage \
    --samples-per-iter 400000 \
    --parallel-opts "$parallel_opts" \
    --num-threads "$num_threads" \
    --minibatch-size "$minibatch_size" \
    --num-jobs-nnet 12  --mix-up 8000 \
    --initial-learning-rate 0.01 --final-learning-rate 0.001 \
    --num-hidden-layers $l \
    --pnorm-input-dim 2000 --pnorm-output-dim 400 \
      data/train data/lang exp/tri4a_ali $dir
  fi

  for lm in IRSTLM SRILM; do
  steps/nnet2/decode.sh --nj $njobs \
      --transform-dir exp/tri4a/decode_test_$lm \
      exp/tri4a/graph_$lm data/test $dir/decode_test_$lm
  done

  for x in $dir/decode_*; do
  [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
fi


if [ $stage == 12 ]; then
  echo ============================================================================
  echo "                   config file for nnet3        "
  echo ============================================================================

  hidden_dim=8
  num_epochs=2

  configs=conf/nnet
  mkdir -p $configs

  feat_dim=$(feat-to-dim scp:data/train/feats.scp -)
  num_targets=`tree-info exp/tri4a_ali/tree 2>/dev/null | grep num-pdfs | awk '{print $2}'` || exit 1;

  cat <<EOF > $configs/network.xconfig
input dim=$feat_dim name=input
relu-renorm-layer name=tdnn1 input=Append(input@-2,input@-1,input,input@1,input@2) dim=$hidden_dim
relu-renorm-layer name=tdnn2 dim=$hidden_dim
relu-renorm-layer name=tdnn3 input=Append(-1,2) dim=$hidden_dim
relu-renorm-layer name=tdnn4 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn5 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn6 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn7 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn8 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn9 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn10 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnn11 input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=tdnnFINAL input=Append(-3,3) dim=$hidden_dim
relu-renorm-layer name=prefinal-affine-layer input=tdnnFINAL dim=$hidden_dim
output-layer name=output dim=$num_targets max-change=1.5	 
EOF
        
  steps/nnet3/xconfig_to_configs.py \
    --xconfig-file $configs/network.xconfig \
    --config-dir $configs/
fi

if [ $stage == 13 ]; then
        
  echo "### =================== ###"
  echo "### MAKE NNET3 EGS DIR  ###"
  echo "### =================== ###"

  steps/nnet3/get_egs.sh \
	  --cmd "$train_cmd" \
	  --cmvn-opts "--norm-means=false --norm-vars=false" \
    --left-context 30 \
    --right-context 31 \
	  $data_dir $ali_dir $master_egs_dir || exit 1;

fi

if [ $stage == 14 ]; then

    echo "### ================ ###"
    echo "### BEGIN TRAIN NNET ###"
    echo "### ================ ###"

    steps/nnet3/train_raw_dnn.py \
        --stage=-5 \
        --cmd="$cmd" \
        --trainer.num-epochs $num_epochs \
        --trainer.optimization.num-jobs-initial=1 \
        --trainer.optimization.num-jobs-final=1 \
        --trainer.optimization.initial-effective-lrate=0.0015 \
        --trainer.optimization.final-effective-lrate=0.00015 \
        --trainer.optimization.minibatch-size=256,128 \
        --trainer.samples-per-iter=10000 \
        --trainer.max-param-change=2.0 \
        --trainer.srand=0 \
        --feat.cmvn-opts="--norm-means=false --norm-vars=false" \
        --feat-dir $data_dir \
        --egs.dir $master_egs_dir \
        --use-dense-targets false \
        --targets-scp $ali_dir \
        --cleanup.remove-egs true \
        --use-gpu false \
        --dir=$exp_dir  \
        || exit 1;
    

    
    # Get training ACC in right format for plotting
    utils/format_accuracy_for_plot.sh "exp_${your_corpus}/nnet3/easy/log" "ACC_nnet3_easy.txt";

    nnet3-am-init $ali_dir/final.mdl $exp_dir/final.raw $exp_dir/final.mdl || exit 1;

    echo "### ============== ###"
    echo "### END TRAIN NNET ###"
    echo "### ============== ###"

fi
