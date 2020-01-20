# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
#!/bin/bash
# Downloads the data and creates data/all-clean.tgz within the current directory

set -e
set -o pipefail

SRC=en
KH_TGT=kh

ROOT=$(dirname "$0")
DATA=$ROOT/data
KH_ROOT=$DATA/all-clean-kh

mkdir -p $DATA $$KH_ROOT

# TODO: We also want to use train.alt from http://lotus.kuee.kyoto-u.ac.jp/WAT/km-en-data/
KH_OPUS_DATASETS=(
  "$KH_ROOT/GNOME.en-ne"
  "$KH_ROOT/Ubuntu.en-ne"
  "$KH_ROOT/KDE4.en-ne"  
)

# TODO: We also want to use train.alt from http://lotus.kuee.kyoto-u.ac.jp/WAT/km-en-data/
KH_OPUS_URLS=(
  "https://object.pouta.csc.fi/OPUS-GNOME/v1/moses/en-kh.txt.zip"
  "https://object.pouta.csc.fi/OPUS-Ubuntu/v14.10/moses/en-kh.txt.zip"
  "https://object.pouta.csc.fi/OPUS-KDE4/v2/moses/en-kh.txt.zip"
)

REMOVE_FILE_PATHS=()

# Example: download_opus_data $LANG_ROOT $TGT
download_opus_data() {
  LANG_ROOT=$1
  TGT=$2

  if [ "$TGT" = "kh" ]; then
    URLS=("${KH_OPUS_URLS[@]}")
    DATASETS=("${KH_OPUS_DATASETS[@]}")
  else
    URLS=()
    DATASETS=()
  fi

  # Download and extract data
  for ((i=0;i<${#URLS[@]};++i)); do
    URL=${URLS[i]}
    CORPORA=${DATASETS[i]}

    download_data $CORPORA $URL
    unzip -o $CORPORA -d $LANG_ROOT
    REMOVE_FILE_PATHS+=( $CORPORA $CORPORA.xml $CORPORA.ids $LANG_ROOT/README $LANG_ROOT/LICENSE )
  done

  cat ${DATASETS[0]}.$SRC ${DATASETS[1]}.$SRC ${DATASETS[2]}.$SRC > $LANG_ROOT/GNOMEKDEUbuntu.$SRC-$TGT.$SRC
  cat ${DATASETS[0]}.$TGT ${DATASETS[1]}.$TGT ${DATASETS[2]}.$TGT > $LANG_ROOT/GNOMEKDEUbuntu.$SRC-$TGT.$TGT

  REMOVE_FILE_PATHS+=( ${DATASETS[0]}.$SRC ${DATASETS[1]}.$SRC ${DATASETS[2]}.$SRC )
  REMOVE_FILE_PATHS+=( ${DATASETS[0]}.$TGT ${DATASETS[1]}.$TGT ${DATASETS[2]}.$TGT )
}

download_opus_data $KH_ROOT $KH_TGT

# Remove the temporary files
for ((i=0;i<${#REMOVE_FILE_PATHS[@]};++i)); do
  rm -rf ${REMOVE_FILE_PATHS[i]}
done
