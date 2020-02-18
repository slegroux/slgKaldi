#!/usr/bin/env python
import os
import glob
import sys
from shutil import copyfile
import uuid
import argparse


def diarize(audio_path:str, n_speakers:int)->str:
    audio_dir='1file'
    dataset='1file'
    uid = uuid.uuid4()

    cmd = "./run.sh --stage 0" + \
        " --audio_dir " + audio_dir + \
        " --dataset " + dataset

    res = "exp/xvectors_" + dataset + "_cmn_segmented/plda_scores_speakers_supervised/rttm"
    wavs = glob.glob(audio_dir + '/*.wav')
    
    for wav in wavs:
        try:
            os.remove(wav)
        except:
            print("error while deleting file", wav)
    
    try:
        copyfile(audio_path, audio_dir + '/uid.wav')
    except IOError as e:
        print("Unable to copy file. %s" % e)
        sys.exit(1)
    except:
        print("Unexpected error:", sys.exc_info())
        sys.exit(1)
    
    os.system(cmd)
    return(res)


if __name__ == "__main__":
    pass