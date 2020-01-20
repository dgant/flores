# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
#!/bin/bash

SRC=km
TGT=en

BPESIZE=5000
TRAIN_MINLEN=6  # remove sentences with <6 BPE tokens
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens

ROOT=$(dirname "$0")
SCRIPTS=$ROOT/scripts
DATA=$ROOT/data
TMP=$DATA/wiki_${SRC}_${TGT}_bpe${BPESIZE}
DATABIN=$ROOT/data-bin/wiki_${SRC}_${TGT}_bpe${BPESIZE}
mkdir -p $TMP $DATABIN

SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py

wget -P $DATA https://object.pouta.csc.fi/OPUS-JW300/v1/raw/en.zip 

python $SPM_TRAIN \
  --input=$TMP/train.$SRC