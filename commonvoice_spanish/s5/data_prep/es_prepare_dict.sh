#!/usr/bin/env bash

# Copyright 2017 John Morgan
# 2020 Sylvain Le Groux
# Apache 2.0.

set -o errexit

unk="<UNK>"

. utils.sh
. path.sh
. utils/parse_options.sh

src=$1
dst=$2

log_info "Prepare letter-based dictionary from $source"

if [ ! -d $dst ]; then
    mkdir -p $dst
fi

export LC_ALL=C
nj=$[ $(nproc) - 2]
cut -f2- $src | \
  tr -s '[:space:]' '[\n*]' | \
    grep -v SPN | sort -u --parallel=$nj>${dst}/nonsilence_phones.txt

# sed "1d" deletes the last line.
expand -t 1 $src | sort -u --parallel=$nj |
   sed "1d" >${dst}/lexicon.txt

echo "${unk} SPN" >> ${dst}/lexicon.txt

# silence phones, one per line.
{
    echo SIL;
    echo SPN;
} >${dst}/silence_phones.txt

echo SIL >${dst}/optional_silence.txt

(
  tr '\n' ' ' <${dst}/silence_phones.txt;
  echo;
  tr '\n' ' ' <${dst}/nonsilence_phones.txt;
  echo;
) >${dst}/extra_questions.txt

echo "Finished dictionary preparation."
