#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# chain lang topo
lang=data/lang
lang_chain=data/lang_chain_500
dataset=data/train500
lores=${dataset}_sp_vp
hires=${dataset}_sp_vp_hires
tri3=exp/tri3_500
tree=exp/chain/tree_train_500
./dnn/make_lang_chain.sh ${dataset}_sp_vp ${tri3} ${lang} ${lang_chain} ${tree}