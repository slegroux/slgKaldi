#!/usr/bin/env python

import os
import glob
import sys
from shutil import copyfile, rmtree
import uuid
import argparse
from IPython import embed
from pathlib import Path
import csv
import json


def rttm2json(rttm_path:Path):

    diarized = {'num_speakers': None, 'segments': None}
    output = {'request_id': None, 'response': None}
    segments = []
    unique_spk = set()
    uid = rttm_path[13:13+36]

    with Path(rttm_path).open() as f:
        for row in f:
            segment = {'speaker_id': None, 'start': None, 'end': None}
            segment['start'] = float(row.split()[3])
            segment['end'] = segment['start'] + float(row.split()[4])
            segment['speaker_id'] = row.split()[7]
            unique_spk.add(segment['speaker_id'])
            segments.append(segment)
    
    diarized = {'num_speakers': len(unique_spk), 'segments': segments}
    output = {'request_id': uid, 'response': diarized}
    return(json.dumps(output, indent=2))


def diarize(audio_path:str, n_speakers:int)->str:
    
    uid = uuid.uuid4()
    process_dir = 'data/' + str(uid)
    try:
        os.mkdir(process_dir)
    except IOError as e:
        print("can't make dir %s" %e)
        sys.exit(1)
    reco2num_spk = str(uid) + '.spk'
    
    with open(process_dir + "/" + reco2num_spk, 'w') as f:
        f.write(str(uid) + " " + str(n_speakers) + "\n")
    
    cmd = "./run.sh --stage 0" + \
        " --audio_dir " + process_dir + \
        " --dataset " + str(uid) + \
        " --reco2num_spk " + reco2num_spk

    rttm_path = "exp/xvectors_" + str(uid) + "_cmn_segmented/plda_scores_speakers_supervised/rttm"

    try:
        copyfile(audio_path, process_dir + '/' + str(uid) + '.wav')
    except IOError as e:
        print("Unable to copy file. %s" % e)
        sys.exit(1)
    except:
        print("Unexpected error:", sys.exc_info())
        sys.exit(1)
    
    os.system(cmd)
    
    res = rttm2json(rttm_path)
    
    try:
        rmtree(process_dir)
        rmtree(process_dir + "_cmn")
        rmtree(process_dir + "_cmn_segmented")
        rmtree("exp/xvectors_" + str(uid) + "_cmn_segmented")
    except IOError as e:
        print("error while deleting folder %s", e)
    
    return(res)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='diarization server')
    parser.add_argument('wavfile', type=str)
    parser.add_argument('nspeakers', type=int)
    args = parser.parse_args()
    diarize(args.wavfile, args.nspeakers)