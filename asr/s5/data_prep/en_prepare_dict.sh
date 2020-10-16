#!/usr/bin/env bash

# Copyright 2014 Vassil Panayotov
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>
# Apache 2.0

# Prepares the dictionary and auto-generates the pronunciations for the words,
# that are in our vocabulary but not in CMUdict

stage=0
nj=4 # number of parallel Sequitur G2P jobs, we would like to use
cmd=run.pl
unk="<UNK>"

. utils/parse_options.sh || exit 1;
. ./path.sh || exit 1

if [ $# -ne 2 ]; then
  echo "Usage: $0 [options] <lexiconr> <dict>"
  echo "Options:"
  echo "  --cmd '<command>'    # script to launch jobs with, default: run.pl"
  echo "  --nj <nj>            # number of jobs to run, default: 4."
  exit 1
fi

lexicon=$1
dict=$2

# this file is either a copy of the lexicon we download from openslr.org/11 or is
# created by the G2P steps below
lexicon_raw_nosil=$dict/lexicon_raw_nosil.txt

mkdir -p $dict || exit 1;

# The copy operation below is necessary, if we skip the g2p stages(e.g. using --stage 3)
if [[ ! -s "$lexicon_raw_nosil" ]]; then
  cat $lexicon |tr [:upper:] [:lower:] > $lexicon_raw_nosil || exit 1
fi

if [ $stage -le 3 ]; then
  silence_phones=$dict/silence_phones.txt
  optional_silence=$dict/optional_silence.txt
  nonsil_phones=$dict/nonsilence_phones.txt
  extra_questions=$dict/extra_questions.txt

  echo "Preparing phone lists and clustering questions"
  (echo SIL; echo SPN;) > $silence_phones
  echo SIL > $optional_silence
  # nonsilence phones; on each line is a list of phones that correspond
  # really to the same base phone.
  awk '{for (i=2; i<=NF; ++i) { print $i; gsub(/[0-9]/, "", $i); print $i}}' $lexicon_raw_nosil |\
    sort -u |\
    perl -e 'while(<>){
      chop; m:^([^\d]+)(\d*)$: || die "Bad phone $_";
      $phones_of{$1} .= "$_ "; }
      foreach $list (values %phones_of) {print $list . "\n"; } ' | sort \
      > $nonsil_phones || exit 1;
  # A few extra questions that will be added to those obtained by automatically clustering
  # the "real" phones.  These ask about stress; there's also one for silence.
  cat $silence_phones| awk '{printf("%s ", $1);} END{printf "\n";}' > $extra_questions || exit 1;
  cat $nonsil_phones | perl -e 'while(<>){ foreach $p (split(" ", $_)) {
    $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' \
    >> $extra_questions || exit 1;
  echo "$(wc -l <$silence_phones) silence phones saved to: $silence_phones"
  echo "$(wc -l <$optional_silence) optional silence saved to: $optional_silence"
  echo "$(wc -l <$nonsil_phones) non-silence phones saved to: $nonsil_phones"
  echo "$(wc -l <$extra_questions) extra triphone clustering-related questions saved to: $extra_questions"
fi

if [ $stage -le 4 ]; then
  (echo '!SIL SIL'; echo '<SPOKEN_NOISE> SPN'; echo "${unk} SPN"; ) |\
  cat - $lexicon_raw_nosil | sort | uniq >$dict/lexicon.txt
  echo "Lexicon text file saved as: $dict/lexicon.txt"
fi

exit 0