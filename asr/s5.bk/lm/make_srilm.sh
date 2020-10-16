#!/usr/bin/env bash

# Copyright 2017 John Morgan
# Apache 2.0.

set -e
. path.sh

stage=0
unk="<UNK>"

. utils/parse_options.sh

corpus=$1
lm=$2

if [ ! -f $corpus ]; then
  echo "$0: input data $corpus not found."
  exit 1
fi

if ! command ngram-count >/dev/null; then
  if uname -a | grep 64 >/dev/null; then # some kind of 64 bit...
    sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
  else
    sdir=$KALDI_ROOT/tools/srilm/bin/i686
  fi
  if [ -f $sdir/ngram-count ]; then
    echo Using SRILM tools from $sdir
    export PATH=$PATH:$sdir
  else
    echo You appear to not have SRILM tools installed, either on your path,
    echo or installed in $sdir.  See tools/install_srilm.sh for installation
    echo instructions.
    exit 1
  fi
fi

if [ $stage -le 0 ]; then
  ngram-count -order 3 -interpolate -unk -map-unk ${unk} \
      -limit-vocab -text $corpus -lm ${lm}/3-gram-srilm.arpa || exit 1;

  gzip -f ${lm}/3-gram-srilm.arpa
fi

if [ $stage -le 1 ]; then
  ngram-count -order 4 -interpolate -unk -map-unk ${unk} \
      -limit-vocab -text $corpus -lm ${lm}/4-gram-srilm.arpa || exit 1;

  gzip -f ${lm}/4-gram-srilm.arpa
fi