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

URLS=(
    # TODO: What should this be?
    "https://github.com/facebookresearch/flores/raw/master/data/wikipedia_en_ne_si_test_sets.tgz"
)
ARCHIVES=(
    # TODO: What should this be?
    "wikipedia_en_ne_si_test_sets.tgz"
)
TRAIN_SETS=(
    "all-clean-si/GNOMEKDEUbuntu.en-si"
    "all-clean-si/OpenSubtitles2018.en-si"
)
# TODO: What should this be?
VALID_SET="wikipedia_en_ne_si_test_sets/wikipedia.dev.si-en"
# TODO: What should this be?
TEST_SET="wikipedia_en_ne_si_test_sets/wikipedia.devtest.si-en"

if [ ! -d $DATA/all-clean-km ]; then
    echo "Data directory not found. Please run 'bash download-data.sh' first..."
    exit -1
fi

# download and extract data
for ((i=0;i<${#URLS[@]};++i)); do
    ARCHIVE=$DATA/${ARCHIVES[i]}
    if [ -f $ARCHIVE ]; then
        echo "$ARCHIVE already exists, skipping download"
    else
        URL=${URLS[i]}
        wget -P $DATA "$URL"
        if [ -f $ARCHIVE ]; then
            echo "$URL successfully downloaded."
        else
            echo "$URL not successfully downloaded."
            exit -1
        fi
    fi
    FILE=${ARCHIVE: -4}
    if [ -e $FILE ]; then
        echo "$FILE already exists, skipping extraction"
    else
        tar -C $DATA -xzvf $ARCHIVE
    fi
done

# learn BPE with sentencepiece
python $SPM_TRAIN \
  --input=$TMP/train.$SRC,$TMP/train.$TGT \
  --model_prefix=$DATABIN/sentencepiece.bpe \
  --vocab_size=$BPESIZE \
  --character_coverage=1.0 \
  --model_type=bpe

# encode train/valid/test
python $SPM_ENCODE \
  --model $DATABIN/sentencepiece.bpe.model \
  --output_format=piece \
  --inputs $TMP/train.$SRC $TMP/train.$TGT \
  --outputs $TMP/train.bpe.$SRC $TMP/train.bpe.$TGT \
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
  --trainpref $TMP/train.bpe --validpref $TMP/valid.bpe --testpref $TMP/test.bpe \
  --destdir $DATABIN \
  --joined-dictionary \
  --workers 4