#!/usr/bin/env bash

# Copyright 2012  Johns Hopkins University (author: Daniel Povey)  Tony Robinson
#           2017  Hainan Xu
#           2017  Ke Li
#           2018  François Hernandez (Ubiqus)
#           2020  Sylvain Le Groux


# Begin configuration section.

embedding_dim=800 #800
lstm_rpd=200
lstm_nrpd=200
stage=-10
train_stage=-10
epochs=40
n_gpu=8
unk="<UNK>"

. utils.sh
. cmd.sh
. utils/parse_options.sh

dir=$1
wordlist=$2
text_dir=$3

#dev_sents=10000

mkdir -p $dir/config
mkdir -p $
set -e

for f in $text $wordlist; do
  [ ! -f $f ] && \
    echo "$0: expected file $f to exist; search for local/prepare_data.sh and utils/prepare_lang.sh in run.sh" && exit 1
done


if [ $stage -le 1 ]; then
  cp $wordlist $dir/config/
  n=`cat $dir/config/words.txt | wc -l`
  echo "<brk> $n" >> $dir/config/words.txt

  # words that are not present in words.txt but are in the training or dev data, will be
  # mapped to <unk> during training.
  echo ${unk} >$dir/config/oov.txt

  cat > $dir/config/data_weights.txt <<EOF
train 1 1.0
EOF

  rnnlm/get_unigram_probs.py --vocab-file=$dir/config/words.txt \
                             --unk-word=${unk} \
                             --data-weights-file=$dir/config/data_weights.txt \
                             $text_dir | awk 'NF==2' >$dir/config/unigram_probs.txt


  rnnlm/choose_features.py --unigram-probs=$dir/config/unigram_probs.txt \
                           --use-constant-feature=true \
                           --top-word-features=10000 \
                           --min-frequency 1.0e-03 \
                           --special-words='<s>,</s>,<brk>,<UNK>' \
                           $dir/config/words.txt > $dir/config/features.txt
  
  rnnlm/validate_features.py $dir/config/features.txt

  cat >$dir/config/xconfig <<EOF
input dim=$embedding_dim name=input
relu-renorm-layer name=tdnn1 dim=$embedding_dim input=Append(0, IfDefined(-1))
fast-lstmp-layer name=lstm1 cell-dim=$embedding_dim recurrent-projection-dim=$lstm_rpd non-recurrent-projection-dim=$lstm_nrpd
relu-renorm-layer name=tdnn2 dim=$embedding_dim input=Append(0, IfDefined(-2))
fast-lstmp-layer name=lstm2 cell-dim=$embedding_dim recurrent-projection-dim=$lstm_rpd non-recurrent-projection-dim=$lstm_nrpd
relu-renorm-layer name=tdnn3 dim=$embedding_dim input=Append(0, IfDefined(-1))
output-layer name=output include-log-softmax=false dim=$embedding_dim
EOF
  rnnlm/validate_config_dir.sh $text_dir $dir/config
fi


if [ $stage -le 2 ]; then
  # the --unigram-factor option is set larger than the default (100)
  # in order to reduce the size of the sampling LM, because rnnlm-get-egs
  # was taking up too much CPU (as much as 10 cores).
  rnnlm/prepare_rnnlm_dir.sh --unigram-factor 100.0 \
    $text_dir $dir/config $dir
fi
echo "rnnlm dir done"

if [ $stage -le 3 ]; then
  log_info rnnlm/train_rnnlm.sh --use-gpu true --use-gpu-for-diagnostics true --num-jobs-initial $n_gpu --num-jobs-final $n_gpu \
    --stage $train_stage --num-epochs $epochs --cmd "run.pl" $dir
fi


exit 0
