#!/usr/bin/env bash

. path.sh

for i in {steps,utils,sid,diarization,rnnlm}; do
    if [ -L $i ]; then
	rm $i
    fi
done

ln -s $KALDI_ROOT/egs/wsj/s5/steps steps
ln -s $KALDI_ROOT/egs/wsj/s5/utils utils
ln -sf $KALDI_ROOT/egs/sre08/v1/sid sid
ln -sf $KALDI_ROOT/egs/callhome_diarization/v1/diarization diarization
ln -sf $KALDI_ROOT/egs/wsj/s5/rnnlm  
