#!/usr/bin/env python

import json
import sys

"""
Pandoc filter to convert all level 2+ headers to paragraphs with
emphasized text.
"""

from pandocfilters import walk, RawBlock


def isH1(key, value):
  return key == 'Header' and value[0] == 1

def isH1WithClass(key, value, className):
  return key == 'Header' and value[0] == 1 and className in value[1][1]

def isSubTitle(key, value):
  return isH1WithClass(key, value, u'ew-pandoc-subtitle')

# see https://github.com/jgm/pandoc/issues/1063
def isTitle(key, value):
  return isH1WithClass(key, value, u'ew-pandoc-title')

def isPageBreak(key, value):
  return isH1WithClass(key, value, u'ew-pandoc-pagebreak')

def isHr(key, value):
  return key == 'HorizontalRule'

# key is a pandoc type, generally "Header", "String" "Para",...
# value is either a string (if key is String) or a list otherwise.
# If a list, value's structure depends on type
#
# If key == 'Header', value will be like:
#
#  {
#    "c": 
#      [ 1, 
#        ["", ["someClass", "someClass2"], []],
#        [{"c": "WordOne", "t": "Str"}, {"c": [], "t": "Space"}, {"c": "WordTwo", "t": "Str"}]
#      ], 
#    "t": "Header"
#  }
def extract_metadata(key, value, format, meta):
  # FIXME: isTitle fails!!!!
  if isTitle(key,value):
    meta["title"] = { "c": value[2], "t": "MetaInlines" }
    return []
  if isSubTitle(key,value):
    meta["subtitle"] = { "c": value[2], "t": "MetaInlines" }
    return []

def fix_hr(key, value, format, meta):
  if key == "HorizontalRule":
    return RawBlock('latex', '\\hrulefill')

def fix_pagebreaks(key, value, format, meta):
  if isPageBreak(key,value):
    return RawBlock('latex', '\\pagebreak')

def toJSONFilter():

  doc = json.loads(sys.stdin.read())
  if len(sys.argv) > 1:
    format = sys.argv[1]
  else:
    format = ""

  # first, process metadata (title and subtitle)
  result_meta = doc[0]['unMeta']
  doc = walk(doc, extract_metadata, format, result_meta)
  doc[0]['unMeta'] = result_meta

  # then, fix page breaks
  doc = walk(doc, fix_pagebreaks, format, result_meta)

  # then, customize horizontal rules (otherwise they're hardcoded in Writers/LaTeX.hs)
  doc = walk(doc, fix_hr, format, result_meta)

  json.dump(doc, sys.stdout)

if __name__ == "__main__":
  toJSONFilter()
