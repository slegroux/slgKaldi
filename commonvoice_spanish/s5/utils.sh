#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

get_njobs(){
    dataset=$1
    local nj
    njobs=$(($(nproc)-2)) # saving at least 2 cpu
    n_speakers_test=$(cat ${dataset}/spk2utt | wc -l)
    if [ $njobs -le $n_speakers_test ]; then
        nj=$njobs
    else
        nj=$n_speakers_test
    fi
    echo $nj
}

LOG_FILE=WER.txt

log_time(){
    start=$(date +%s)
    "$@"
    end=$(date +%s)
    runtime=$((end-start))
    echo "[CMD] $@" | tee -a $LOG_FILE
    echo "[RUNTIME] $runtime" | tee -a $LOG_FILE
}

log_info(){
    msg=$1
    echo -e "\n[INFO] $(date +'%Y-%m-%d-%H-%M-%S')" $msg | tee -a $LOG_FILE
}

log_wer(){
    decode_dir=$1
    echo "[WER]" $(grep WER ${decode_dir}/wer_* | utils/best_wer.sh) | tee -a $LOG_FILE
}