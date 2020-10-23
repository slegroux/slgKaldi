#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

ip=dx05
port_num=5050
sr=16k

. utils.sh
. path.sh
. utils/parse_options.sh

rec -r ${sr} -e signed-integer -c 1 -b 16 -t raw -q - | nc ${ip} ${port_num} # nc -N for linux
