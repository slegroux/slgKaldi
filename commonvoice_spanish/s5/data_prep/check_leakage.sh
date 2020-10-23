#!/usr/bin/env bash
DATA="/home/syl20/kaldi-gc/kaldi_egs/commonvoice_spanish/s5/experiments/es/commonvoice/data"


echo "[INFO] DATA " $DATA
echo "[INFO] UTTS"
echo "[INFO] train utts: " $(cat $DATA/train/text|wc -l) "test utts: " $(cat $DATA/test/text|wc -l) "dev utts: "$(cat $DATA/dev/text|wc -l)
echo "[INFO] overlap train/test text: " $(comm -12 <(cat $DATA/train/text | cut -d ' ' -f2- | sort) <(cat $DATA/test/text | cut -d ' ' -f2- | sort) |wc -l)
echo "[INFO] overlap train/dev text: " $(comm -12 <(cat $DATA/train/text | cut -d ' ' -f2- | sort) <(cat $DATA/dev/text | cut -d ' ' -f2- | sort) |wc -l)
echo "[INFO] overlap test/dev text: " $(comm -12 <(cat $DATA/test/text | cut -d ' ' -f2- | sort) <(cat $DATA/dev/text | cut -d ' ' -f2- | sort) |wc -l)

echo "[INFO] SPK"
echo "[INFO] train spk: " $(cat $DATA/train/spk2utt|wc -l) "test spk: " $(cat $DATA/test/spk2utt|wc -l) "dev spk: " $(cat $DATA/dev/spk2utt|wc -l)
echo "[INFO] overlap train/test text: " $(comm -12 <(cat $DATA/train/spk2utt | awk '{ print $1 }'| sort) <(cat $DATA/test/spk2utt | awk '{ print $1 }' | sort) |wc -l)
echo "[INFO] overlap train/dev text: " $(comm -12 <(cat $DATA/train/spk2utt | awk '{ print $1 }'| sort) <(cat $DATA/dev/spk2utt | awk '{ print $1 }' | sort) |wc -l)
echo "[INFO] overlap test/dev text: " $(comm -12 <(cat $DATA/test/spk2utt | awk '{ print $1 }'| sort) <(cat $DATA/dev/spk2utt | awk '{ print $1 }' | sort) |wc -l)
