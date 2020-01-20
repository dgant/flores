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
KM_TGT=km

ROOT=$(dirname "$0")
DATA=$ROOT/data
KM_ROOT=$DATA/all-clean-km
mkdir -p $DATA $KM_ROOT

# TODO: We also want to use train.alt from http://lotus.kuee.kyoto-u.ac.jp/WAT/km-en-data/
KM_OPUS_DATASETS=(
  "$KM_ROOT/GNOME.en-km"
  "$KM_ROOT/GNOME.en-km"
  "$KM_ROOT/KDE4.en-km"
  "$KM_ROOT/KDE4.en-km"
  "$KM_ROOT/Ubuntu.en-km"
  "$KM_ROOT/Ubuntu.en-km"  
)

# TODO: We also want to use train.alt from http://lotus.kuee.kyoto-u.ac.jp/WAT/km-en-data/
KM_OPUS_URLS=(
  "https://object.pouta.csc.fi/OPUS-GNOME/v1/raw/en.zip"
  "https://object.pouta.csc.fi/OPUS-GNOME/v1/raw/km.zip"
  "https://object.pouta.csc.fi/OPUS-KDE4/v2/raw/en.zip"
  "https://object.pouta.csc.fi/OPUS-KDE4/v2/raw/km.zip"
  "https://object.pouta.csc.fi/OPUS-Ubuntu/v14.10/raw/en.zip"
  "https://object.pouta.csc.fi/OPUS-Ubuntu/v14.10/raw/km.zip"
  #"https://object.pouta.csc.fi/OPUS-GNOME/v1/moses/en-km.txt.zip"
  #"https://object.pouta.csc.fi/OPUS-Ubuntu/v14.10/moses/en-km.txt.zip"
  #"https://object.pouta.csc.fi/OPUS-KDE4/v2/moses/en-km.txt.zip"
)

REMOVE_FILE_PATHS=()

# Download data
download_data() {
  CORPORA=$1
  URL=$2

  if [ -f $CORPORA ]; then
    echo "$CORPORA already exists, skipping download"
  else
    echo "Downloading $URL"
    wget $URL -O $CORPORA --no-check-certificate || rm -f $CORPORA
    if [ -f $CORPORA ]; then
      echo "$URL successfully downloaded."
    else
      echo "$URL not successfully downloaded."
      rm -f $CORPORA
      exit -1
    fi
  fi
}

# Example: download_opus_data $LANG_ROOT $TGT
download_opus_data() {
  LANG_ROOT=$1
  TGT=$2
  echo "Downloading OPUS data for language $LANG_ROOT to target $TGT"

  if [ "$TGT" = "km" ]; then
    URLS=("${KM_OPUS_URLS[@]}")
    DATASETS=("${KM_OPUS_DATASETS[@]}")
  else
    echo "Warning: Target $TGT not recognized"
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

download_opus_data $KM_ROOT $KM_TGT

# Remove the temporary files
for ((i=0;i<${#REMOVE_FILE_PATHS[@]};++i)); do
  rm -rf ${REMOVE_FILE_PATHS[i]}
done
