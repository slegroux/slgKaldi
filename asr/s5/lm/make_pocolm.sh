#!/usr/bin/env bash
# (c) 2018 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# TODO(slg):
# - make sure log_info inside pushd is kept
# - log ppl too

order=3
wordlist=
limit_unk_history=true

. path.sh
. utils/parse_options.sh
. utils.sh

if [ $# != 3 ]; then
  echo "Usage: make_pocolm.sh <corpus> <dir>"
  echo "main options (for others, see top of script file): "
  echo "--order <order>                           # order of language model (default trigram) "
  echo "--wordlist <wordlist>                     # word list"
  exit 1;
fi

train=$1
dev=$2
pocolm_dir=$3

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
# num_dev_sentences=$(echo "$(cat ${corpus} | wc -l) * 20 / 100" | bc)
# tail -n $num_dev_sentences < ${corpus} > $pocolm_data_dir/dev.txt
# head -n -$num_dev_sentences < ${corpus} > $pocolm_data_dir/train.txt
cp ${train} $pocolm_data_dir/train.txt
cp ${dev} $pocolm_data_dir/dev.txt

POCOLM_PATH=${KALDI_ROOT}/tools/pocolm
log_info "Train ${order}-gram LM with pocolm"
pushd ${POCOLM_PATH}
python2 scripts/train_lm.py \
  --limit-unk-history=${limit_unk_history} \
  --num-splits=100 \
  --fold-dev-into=train \
  --warm-start-ratio=1 \
  --min-counts="train=2" \
  ${pocolm_data_dir} ${order} ${lm_work_dir} ${unpruned_model_dir}

log_time python2 scripts/format_arpa_lm.py ${unpruned_model_dir} | gzip -c > $pocolm_arpa_file
log_time python2 scripts/get_data_prob.py $pocolm_data_dir/dev.txt $unpruned_model_dir 2>&1 | grep -F '[perplexity'
popd

exit 0