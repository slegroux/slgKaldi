#!/bin/bash

. ./cmd.sh
. ./path.sh

stage=0

datadir=$DATA/Spanish/common_voice

# The corpus and lexicon are on openslr.org
#speech_url="http://www.openslr.org/resources/39/LDC2006S37.tar.gz"
lexicon_url="http://www.openslr.org/resources/34/santiago.tar.gz"

# Location of the Movie subtitles text corpus
subtitles_url="http://opus.lingfil.uu.se/download.php?f=OpenSubtitles2018/en-es.txt.zip"

. utils/parse_options.sh

set -e
set -o pipefail
set -u
set -x

njobs=$(($(nproc)-1))

# don't change tmpdir, the location is used explicitly in scripts in local/.
tmpdir=data/local/tmp

if [ $stage -le 0 ]; then
  if [ ! -d $datadir ]; then
    echo "$0: please download and un-tar https://voice-prod-bundler-ee1969a6ce8178826482b88e843c335139bd3fb4.s3.amazonaws.com/cv-corpus-4-2019-12-10/es.tar.gz"
    echo "  and set $datadir to the directory where it is located."
    exit 1
  fi
  if [ ! -s santiago.txt ]; then
    echo "$0: downloading the lexicon"
    wget -c http://www.openslr.org/resources/34/santiago.tar.gz
    tar -xvzf santiago.tar.gz
  fi
  # Get data for lm training
  local/subs_download.sh $subtitles_url
fi

if [ $stage -le 1 ]; then
  echo "Making lists for building models."
  local/prepare_data.sh $datadir
fi

if [ $stage -le 2 ]; then
  mkdir -p data/local/dict $tmpdir/dict
  local/prepare_dict.sh
fi

if [ $stage -le 3 ]; then
  utils/prepare_lang.sh \
    data/local/dict "<UNK>" \
    data/local/lang data/lang
fi

if [ $stage -le 4 ]; then
  mkdir -p $tmpdir/subs/lm
  local/subs_prepare_data.pl
fi

if [ $stage -le 5 ]; then
  echo "point 1"
  local/prepare_lm.sh  $tmpdir/subs/lm/in_vocabulary.txt
fi

if [ $stage -le 6 ]; then
  echo "point 2"
  utils/format_lm.sh \
    data/lang data/local/lm/trigram.arpa.gz data/local/dict/lexicon.txt \
    data/lang_test
fi