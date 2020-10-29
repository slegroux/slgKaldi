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
    echo "[RUNTIME] $(date -d@${runtime} -u +%H:%M:%S)" | tee -a ${EXP_LOG}
}

log_info(){
    msg=$1
    echo -e "[INFO] $(date +'%Y-%m-%d-%H-%M-%S')" $msg | tee -a ${EXP_LOG}
}

log_err(){
    msg=$1
    echo - "[ERROR] $msg"| tee -a ${EXP_LOG}
}

log_wer(){
    decode_dir=$1
    echo "[WER]" $(grep WER ${decode_dir}/wer_* | utils/best_wer.sh) | tee -a ${EXP_LOG}
}

log_debug(){
    log_dir=$1
    echo "[LOG] Kaldi logs for this task: ${log_dir}" | tee -a ${EXP_LOG}
}

filter_from_list(){
    # cat exp/20200927/mono/log/align.2.*.log|grep "len = "
    src=$1
    blacklist=$1
    mv ${src} ${src}.tmp
    cat ${src}.tmp |grep -v -f ${blacklist} >${src}
}

get_audio_duration(){
    file_list=$(</dev/stdin)
    secs=$(echo "$file_list" | parallel -I{} --max-args $(( $nproc -2 )) soxi -D {}|paste -sd+|xargs -I% echo '(%)'|bc)
    # convert float to int
    printf -v i %.0f $secs
    declare hr=$( echo "$i/3600"|bc) min=$(echo "$i/60%60"|bc) sec=$(echo "$i%60"|bc);
    printf "duration: %02d:%02d:%02d\n" $hr $min $sec
}