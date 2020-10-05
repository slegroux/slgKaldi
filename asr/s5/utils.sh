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
    echo "[RUNTIME] $(date -d@${runtime} -u +%H:%M:%S)" | tee -a $LOG_FILE
}

log_info(){
    msg=$1
    echo -e "\n[INFO] $(date +'%Y-%m-%d-%H-%M-%S')" $msg | tee -a $LOG_FILE
}

log_wer(){
    decode_dir=$1
    echo "[WER]" $(grep WER ${decode_dir}/wer_* | utils/best_wer.sh) | tee -a $LOG_FILE
}

filter_from_list(){
    # cat exp/20200927/mono/log/align.2.*.log|grep "len = "
    src=$1
    blacklist=$1
    mv ${src} ${src}.tmp
    cat ${src}.tmp |grep -v -f ${blacklist} >${src}
}