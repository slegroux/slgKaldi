#!/usr/bin/env bash

# Copyright 2018 Voicea.ai (Author Sylvain Le Groux)
# Decode and compute best wer with corresponding lmwt


graph_tag=offline
skip_scoring=true

kaldi_model=$DATA/kaldi_models/0001_aspire_chain_model_with_hclg
offline_config=$ASPIRE/conf/decode.config
mfcc_conf=$ASPIRE/conf/mfcc_hires.conf
ivector_extractor=$kaldi_model/exp/nnet3/extractor
graphDir=$kaldi_model/exp/tdnn_7b_chain_online/graph_pp
modelDir=$kaldi_model/exp/chain/tdnn_7b

[ -f ./path.sh ] && . ./path.sh;
[ -f ./cmd.sh ] && . ./cmd.sh;

source utils/parse_options.sh || exit 1;


if [ $# -lt 1 ]; then
  echo "Usage: ./decode.sh <graphDir> <dataDir> <modelDir>"
  echo "main options (for others, see top of script file): "
  echo "--graph_tag <tag>    # to recognize and compare wer results"
  echo "--skip_scoring <bool> "
  echo "--offline_config <configfile> "
  exit 1;
fi

#set -x
dataDir=$1

njobs=$(($(nproc)-1))
n_speakers_test=$(cat $dataDir/spk2utt| wc -l)

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

# include data set repo and graph name to decode repo for future reference/comparison
data_tag=$(basename $dataDir)
decodeDir=${modelDir}/decode_${data_tag}_${graph_tag}

# archive previous decoding dir 
if [ -d $decodeDir ]; then
	echo '[INFO] archive previous decodir' 1>&2
	if [ -d ${decodeDir}~ ]; then
		rm -rf ${decodeDir}~
	fi		 
	mv $decodeDir ${decodeDir}~
fi

if [ -d $dataDir/split${njobs} ]; then
	echo '[INFO] archive previous split' 1>&2
	if [ -d $dataDir/split${njobs}~ ]; then
		rm -rf $dataDir/split${njobs}~
	fi
	mv $dataDir/split${njobs} $dataDir/split${njobs}~
fi

echo '[INFO] validating data dir' 1>&2
./utils/data/fix_data_dir.sh $dataDir 1>&2

echo "[INFO] using $njobs CPUS for decoding" 1>&2
echo "[INFO] MFCC/CMVN" 1>&2
./steps/make_mfcc.sh --mfcc-config $mfcc_conf --nj $nj --cmd "run.pl" $dataDir || exit 1;
utils/fix_data_dir.sh $dataDir
utils/validate_data_dir.sh --no-text $dataDir
steps/compute_cmvn_stats.sh $dataDir

echo "[INFO] ivector" 1>&2
ivector_dev_dir=$dataDir/data
$KALDI/egs/wsj/s5/steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj $dataDir $ivector_extractor $ivector_dev_dir || exit 1;

echo "[INFO] offline decoding" 1>&2
$KALDI/egs/wsj/s5/steps/nnet3/decode.sh \
	--online-ivector-dir $ivector_dev_dir \
	--config $offline_config \
	--acwt 1.0 --post-decode-acwt 10.0 \
	--skip_scoring $skip_scoring \
	--nj $nj --cmd "run.pl" \
	$graphDir $dataDir $decodeDir || exit 1;

# steps/nnet3/decode.sh --nj $njobs --cmd "$decode_cmd" --config $offline_config \
# 				$graphDir $dataDir $decodeDir || exit 1;

while IFS= read -r line; do
	id=$(echo $line | cut -d' ' -f1)
	cat $decodeDir/log/decode.*.log | grep "^$id" |tee -a $dataDir/text
done < $dataDir/wav.scp


if ! $skip_scoring ; then
	echo "[INFO] best WER and corresponding LM weight:"
	for x in $decodeDir; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
fi

