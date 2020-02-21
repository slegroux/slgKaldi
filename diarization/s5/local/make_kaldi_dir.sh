#!/usr/bin/env bash
# 2020 sylvain.legroux@gmail.com

model_sr=8000
dataset=test

. utils/parse_options.sh

audio_dir=$1

set -x
if [ -f data/$dataset/wav.scp ]; then
    echo "wav.scp already exists, archiving"
    mv data/$dataset/wav.scp data/$dataset/wav.scp.bu
fi

if [ -f data/$dataset/utt2spk ]; then
    echo "utt2spk already exists, archiving"
    mv data/$dataset/utt2spk data/$dataset/utt2spk.bu
fi

if [ ! -d data/$dataset ]; then
    mkdir -p data/$dataset
fi

for i in $audio_dir/*.wav; do
    if [ $(soxi -sr $i) -ne $model_sr ]; then
        path="sox $(realpath $i) -r $model_sr -c 1 -e signed -b 16 -t wav - |"
    else
        path=$(realpath $i)
    fi
    id=$(basename $i .wav)
    echo $id $path >> data/$dataset/wav.scp
    echo $id $id >> data/$dataset/utt2spk
done
