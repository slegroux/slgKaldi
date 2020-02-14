#!/usr/bin/env bash

rttm=$1
cat $rttm | tr -s ' ' | cut -d' ' -f4,5,8 | tr ' ' ',' > ${rttm}.sv
