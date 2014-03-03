#!/bin/bash -x

die() {
  echo "Usage: run.sh INPUTFILE.html"
  exit 1
}

FILE=$1
FILE=${FILE//[[:space:]]/}  # remove spaces
FILE=${FILE##*/}  # remove path (keeps only filename)
FILE=${FILE%%.html}   # remove extension
OUTPUT=build/"$FILE"

test -e "$1" || die
mkdir -p $OUTPUT

cp "$1" $OUTPUT/in.html

# run the HTML preprocessor
bundle exec ruby lib/pandoc-preprocess.rb $OUTPUT/in.html > $OUTPUT/preprocessed.html

# run pandoc
pandoc $OUTPUT/preprocessed.html -t json > $OUTPUT/pre.json

# run the custom filter
cat $OUTPUT/pre.json | ./lib/pandoc-filter.py > $OUTPUT/post.json

# run pandoc
#PANDOC_ARGS="--template assets/template.tex"
PANDOC_ARGS="--template assets/template-ew.tex"
PANDOC_ARGS="$PANDOC_ARGS -V numbersections:true"
PANDOC_ARGS="$PANDOC_ARGS -V graphics:true"
# PANDOC_ARGS="$PANDOC_ARGS --chapters"
# PANDOC_ARGS="$PANDOC_ARGS -V toc:true toc-depth:3"

# create main latex document
# cp $OUTPUT/template-ew.tex $OUTPUT/$FILE.tex
# USED TO REQUIRE PANDOC TEMPLATING SYSTEM, NOW DOES NOT:
pandoc $OUTPUT/post.json -t latex $PANDOC_ARGS > $OUTPUT/$FILE.tex

# create just the metadata latex document
pandoc $OUTPUT/post.json --no-wrap -t latex --template assets/template-metadata.tex > $OUTPUT/metadata.tex
pandoc $OUTPUT/post.json --chapters --no-wrap -t latex > $OUTPUT/main.tex

# must use -o with docx output format
pandoc $OUTPUT/post.json -s -t docx -o $OUTPUT/$FILE.docx
pandoc $OUTPUT/post.json -s -t rtf -o $OUTPUT/$FILE.rtf

#prepare the assets
cp assets/* $OUTPUT/

# convert latex to PDF
echo "Created $OUTPUT/$FILE.tex, making $OUTPUT/$FILE.pdf..."
( cd $OUTPUT/ ; rubber --pdf $FILE)
