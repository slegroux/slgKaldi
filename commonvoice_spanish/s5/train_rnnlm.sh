# train rnnlm
if [ $stage -le 7 ]; then
    ./local/rnnlm/run_lstm_tdnn.sh --dir $rnnlm_dir --epochs $rnnlm_epochs --n_gpu $n_gpu \
        --wordlist $wordlist --text_dir $rnnlm_data
fi

# test rnnlm
if [ $stage -le 7 ]; then
    ./local/rnnlm/rescore_vca.sh --rnnlm_dir $rnnlm_dir --lang_dir data/lang_test --test_set $test_set \
        --model $model_dir
fi