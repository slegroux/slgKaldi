#!/usr/bin/env python
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

import click
from slgasr.data import ASRDataset, Audios, Transcripts, TranscriptsCSV
from pathlib import Path
from IPython import embed
# audios: test-clean/speakerid/chapter/speakerid-chapter-uttid.flac
# tr: test-clean/speakerid/chapter/speakerid-chapter.trans.txt
#   speakerid-chapter-uttid text

@click.command()

@click.argument('dataset', default="/home/syl20/data/en/librispeech/LibriSpeech/dev-clean-2")
@click.argument("dst_path", default="/tmp/libri")
@click.option("--lang", default="en")

def format_libri(dataset:str, dst_path:str, lang:str):
    """Format librispeech dataset into kaldi compatible data folder"""
    audio_path = str(Path(dataset) / "*/*/*.flac" )
    transcript_path = str(Path(dataset) / "*/*/*.trans.txt")
    a = Audios(audio_path, lang='en', country='US', sid_from_path=lambda x: Path(x).parents[1].name)
    t = TranscriptsCSV(transcript_path, normalize=True, lang='en', country='US')
    ds = ASRDataset(a.audios, t.transcripts)
    ds.export2kaldi(dst_path, ext='flac')
    
if __name__ == "__main__":
    format_libri()