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
@click.argument("audio_path", default="/home/syl20/data/en/librispeech/LibriSpeech/dev-clean-2/*/*/*.flac")
@click.argument("transcript_path", default="/home/syl20/data/en/librispeech/LibriSpeech/dev-clean-2/*/*/*.trans.txt")
@click.argument("dst_path", default="experiments/en/minilibrispeech/data/dev_clean_2")
@click.option("--lang", default="en")

def format_libri(audio_path, transcript_path, dst_path, lang):
    """Format librispeech dataset into kaldi compatible data folder"""

    a = Audios(audio_path, lang='en', country='US', sid_from_path=lambda x: Path(x).parents[1].name)
    t = TranscriptsCSV(transcript_path, normalize=True, lang='en', country='US')
    ds = ASRDataset(a.audios, t.transcripts)
    ds.export2kaldi(dst_path, ext='flac')
    
if __name__ == "__main__":
    format_libri()