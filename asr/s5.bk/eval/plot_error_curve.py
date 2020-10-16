#!/usr/bin/env python
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

import pandas as pd
from matplotlib import pyplot as plt
# from IPython import embed

fn = "/home/syl20/kaldi-gc/kaldi_egs/commonvoice_spanish/s5/experiments/es/commonvoice/exp/chain/tdnnf_tedlium/accuracy.report"
df = pd.read_csv(fn, sep='\t')
df.plot(x='%Iter',y=['train_objective','valid_objective'])
plt.savefig('error_curve.pdf') 

