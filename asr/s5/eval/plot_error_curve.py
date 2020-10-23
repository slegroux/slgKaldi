#!/usr/bin/env python
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

import pandas as pd
from matplotlib import pyplot as plt
import sys
from pathlib import Path

fn = sys.argv[1]
df = pd.read_csv(fn, sep='\t')
df.plot(x='%Iter',y=['train_objective','valid_objective'])
plt.savefig(str(Path(fn).parent / 'error_curve.pdf'))

