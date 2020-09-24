#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# ./3_monophone_training.sh data/train_500 data/lang exp/mono_500
./3a_am_testing.sh --mono true --compile_graph false data/test35 data/lang_test exp/mono_500 exp/mono_500/graph