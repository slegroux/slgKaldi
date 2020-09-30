#!/usr/bin/env bash
# (c) 2018 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

order=3
wordlist=

. path.sh
. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: make_pocolm.sh <corpus> <dir>"
  echo "main options (for others, see top of script file): "
  echo "--order <order>                           # order of language model (default trigram) "
  echo "--wordlist <wordlist>                     # word list"
  exit 1;
fi

corpus=$1
pocolm_dir=$2

# create necessary folders
mkdir -p $pocolm_dir
pocolm_dir=$(realpath $pocolm_dir)
pocolm_arpa_file=${pocolm_dir}/${order}gram_unpruned.arpa.gz
pocolm_data_dir=$pocolm_dir/data_dir
mkdir -p $pocolm_data_dir
unpruned_model_dir=${pocolm_dir}/unpruned
mkdir -p $unpruned_model_dir
lm_work_dir=${pocolm_dir}/unpruned_work
mkdir -p $lm_work_dir

# take the last 20% as dev set
num_dev_sentences=$(echo "$(cat ${corpus} | wc -l) * 20 / 100" | bc)
tail -n $num_dev_sentences < ${corpus} > $pocolm_data_dir/dev.txt
head -n -$num_dev_sentences < ${corpus} > $pocolm_data_dir/train.txt

POCOLM_PATH=${KALDI_ROOT}/tools/pocolm
pushd ${POCOLM_PATH}
    # --max-memory=10G \
    # --num-splits=1 \
    # --warm-start-ratio=1 \
    # --limit-unk-history=true \
    # --fold-dev-into=train \
    # --min-counts="train=1" \
python scripts/train_lm.py \
    ${pocolm_data_dir} ${order} ${lm_work_dir} ${unpruned_model_dir}

python scripts/format_arpa_lm.py ${unpruned_model_dir} | gzip -c > $pocolm_arpa_file
python scripts/get_data_prob.py $pocolm_data_dir/dev.txt $unpruned_model_dir 2>&1 | grep -F '[perplexity'
popd