#!/bin/bash

die() {
  echo "Usage: run.sh INPUTFILE.html"
  exit 1
}
test -e "$1" || die

lib/pandoc-preprocess.rb $1 \
  | pandoc -f html -t json  \
  | ./lib/pandoc-filter.py \
  | pandoc -f json -t latex --template assets/template.tex \
  > build/out.tex

# To add TOC:
#   | pandoc -f json -t latex --template assets/template.tex -V toc:1 -V toc-depth:3 \

echo "Created build/out.tex, making build/out.pdf..."
( cd build/ ; pdflatex out.tex)
