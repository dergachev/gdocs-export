#!/bin/bash -x

die() {
  echo "Usage: diff.sh old.tex new.tex TARGET_DIR"
  echo "  where A and B are latex files, and C is the target"
  exit 1
}

test -e "$1" || die
test -e "$2" || die
# test -e "$3" || die

FILE=diff
OUTPUT=build/"$FILE"
mkdir -p $OUTPUT

#prepare the assets
cp assets/* $OUTPUT/

# create the diff
latexdiff --flatten $1 $2 > $OUTPUT/$FILE.tex

# need metadata.tex because --flatten ignores preamble
META=`dirname $2` 
cp $META/metadata.tex $OUTPUT

# convert latex to PDF
echo "DIFF: Created $OUTPUT/$FILE.tex, making $OUTPUT/$FILE.pdf..."
( cd $OUTPUT/ ; rubber --pdf $FILE)
