#!/usr/bin/env bash
dataset=$1
cat $dataset/utt2dur |awk '{ print $2 }'|paste -sd+|xargs -I{} echo 'scale=2; ({}) / 3600.' |bc