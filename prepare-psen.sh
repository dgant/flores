# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
#!/bin/bash

SRC=ps
TGT=en

BPESIZE=5000
TRAIN_MINLEN=1  # remove sentences with <1 BPE token
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens 

ROOT=$(dirname "$0")
SCRIPTS=$ROOT/scripts
DATA=$ROOT/data
TMP=$DATA/wiki_${SRC}_${TGT}_bpe${BPESIZE}
DATABIN=$ROOT/data-bin/wiki_${SRC}_${TGT}_bpe${BPESIZE}
mkdir -p $TMP $DATABIN

SRC_TOKENIZER="cat"
TGT_TOKENIZER="cat"  # learn target-side BPE over untokenized (raw) text
SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py

TRAIN_SETS_PS=(
  "all-clean-ps/GNOME.en-ps"
  "all-clean-ps/KDE4.en-ps"
  "all-clean-ps/Tatoeba.en-ps"
  "all-clean-ps/Ubuntu.en-ps"
  "all-clean-ps/wikimedia.en-ps"
)
TRAIN_SETS_HI=(
  "all-clean-hi/IITB.en-hi"
)
TRAIN_SETS_FA=(
  "all-clean-fa/GlobalVoices.en-fa"
  "all-clean-fa/GNOME.en-fa"
  "all-clean-fa/infopankki.en-fa"
  "all-clean-fa/KDE4.en-fa"
  "all-clean-fa/OpenSubtitles.en-fa"
  "all-clean-fa/QED.en-fa"
  "all-clean-fa/Tanzil.en-fa"
  "all-clean-fa/TED2013.en-fa"
  "all-clean-fa/TEP.en-fa"
  "all-clean-fa/Ubuntu.en-fa"
  "all-clean-fa/Wikipedia.en-fa"
)

VALID_SET="../../flores-data-v2/ps-en.dev"
TEST_SET="../../flores-data-v2/ps-en.devtest"

if [ ! -d $DATA/all-clean-ps ]; then
    echo "Data directory not found. Please run 'bash download-data.sh' first..."
    exit -1
fi

for FILE in "${TRAIN_SETS_PS[@]}" ; do
    $SRC_TOKENIZER $DATA/$FILE.ps
done > $TMP/train.ps
for FILE in "${TRAIN_SETS_HI[@]}" ; do
    $SRC_TOKENIZER $DATA/$FILE.hi
done > $TMP/train.hi
for FILE in "${TRAIN_SETS_FA[@]}" ; do
    $SRC_TOKENIZER $DATA/$FILE.fa
done > $TMP/train.fa
for FILE in "${TRAIN_SETS_PS[@]}"; do
    $TGT_TOKENIZER $DATA/$FILE.en
done > $TMP/train.en

echo "pre-processing dev/test data..."
$SRC_TOKENIZER $DATA/${VALID_SET}.$SRC > $TMP/valid.$SRC
$TGT_TOKENIZER $DATA/${VALID_SET}.$TGT > $TMP/valid.$TGT
$SRC_TOKENIZER $DATA/${TEST_SET}.$SRC > $TMP/test.$SRC
$TGT_TOKENIZER $DATA/${TEST_SET}.$TGT > $TMP/test.$TGT

cat $TMP/train.ps | head -100000 > $TMP/train-abridged.ps
cat $TMP/train.fa | head -100000 > $TMP/train-abridged.fa
cat $TMP/train.hi | head -100000 > $TMP/train-abridged.hi
cat $TMP/train.en | head -100000 > $TMP/train-abridged.en

# Take a limited amount of each train set for BPE, so all languages are similarly well-represented

# learn BPE with sentencepiece
python $SPM_TRAIN \
  --input=$TMP/train-abridged.ps,$TMP/train-abridged.fa,$TMP/train-abridged.hi,$TMP/train-abridged.en \
  --model_prefix=$DATABIN/sentencepiece.bpe \
  --vocab_size=$BPESIZE \
  --character_coverage=1.0 \
  --model_type=bpe

# encode train/valid/test
python $SPM_ENCODE \
  --model $DATABIN/sentencepiece.bpe.model \
  --output_format=piece \
  --inputs $TMP/train.ps $TMP/train.fa $TMP/train.hi $TMP/train.en \
  --outputs $TMP/train.bpe.ps $TMP/train.bpe.fa $TMP/train.bpe.hi $TMP/train.bpe.en \
  --min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN
for SPLIT in "valid" "test"; do \
  python $SPM_ENCODE \
    --model $DATABIN/sentencepiece.bpe.model \
    --output_format=piece \
    --inputs $TMP/$SPLIT.$SRC $TMP/$SPLIT.$TGT \
    --outputs $TMP/$SPLIT.bpe.$SRC $TMP/$SPLIT.bpe.$TGT
done

# binarize data
fairseq-preprocess \
  --source-lang $SRC --target-lang $TGT \
  --destdir $DATABIN \
  --joined-dictionary \
  --workers 4 \
  --trainpref $TMP/train.bpe \
  --validpref $TMP/valid.bpe \
   --testpref $TMP/test.bpe
  
