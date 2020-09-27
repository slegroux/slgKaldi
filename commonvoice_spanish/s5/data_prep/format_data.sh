#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh
. utils/parse_options.sh

# conda activate slgasr
./format_commonvoice.py --lang='es' /home/syl20/data/es/commonvoice/test.tsv /tmp/test
