#!/usr/bin/env python

import pandas as pd
from IPython import embed

rttm_path = "data/test/rttm/diarizationExample.s.rttm"

df = pd.read_csv(rttm_path, sep=' ', header=None)
id = df[1]
sid = df[7]
start = df[3]
end = df[3] + df[4]
def format(x:float)->str:
    
    return("{0:0>7}".format( "{0:.2f}".format(x).replace('.','') ))

new_id = sid.apply(str) + '-' + id + '-' + start.apply(format) + '-' + end.apply(format)

segments = pd.concat([new_id, id, start, end], axis=1)
segments.to_csv('data/test/segments', sep=' ',index=False, header=False)
