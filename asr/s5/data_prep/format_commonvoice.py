#!/usr/bin/env python
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

import click
from slgasr.data import ASRDatasetCSV
from pathlib import Path
from IPython import embed

@click.command()
@click.argument("src", default="/home/syl20/data/es/commonvoice/test.tsv")
@click.argument("dst", default="/tmp/es/commonvoice/test")
@click.option("--lang", default="es")
def format_commonvoice(src, dst, lang):
    """Format commonvoice dataset into kaldi compatible data folder"""
    dataset_path = Path(src)
    formatted_dataset_path = Path(dst)
    audio_path = dataset_path.parent / "clips"
    ds = ASRDatasetCSV(dataset_path, lang=lang, prepend_audio_path=str(audio_path.absolute()))
    ds.export2kaldi(str(formatted_dataset_path))

if __name__ == "__main__":
    format_commonvoice()