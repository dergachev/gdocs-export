#!/usr/bin/env python

import json
import sys

"""
Pandoc filter to convert all level 2+ headers to paragraphs with
emphasized text.
"""

from pandocfilters import walk, RawBlock, RawInline, Span, attributes, Str

def isH1WithClass(key, value, className):
  return key == 'Header' and value[0] == 1 and className in value[1][1]

def isSubTitle(key, value):
  return isH1WithClass(key, value, u'ew-pandoc-subtitle')

def isHeader(key, value):
  return isH1WithClass(key, value, u'ew-pandoc-header')

def isFooter(key, value):
  return isH1WithClass(key, value, u'ew-pandoc-footer')

# hacky workaround for pandoc's not supporting <u>
def isUnderline(key, value):
  # if key == 'Span' and value[0][1] == ['underline']:
  #   sys.stderr.write( json.dumps(value[0]) + "\n")
  return key == 'Span' and value[0][1] == ['underline']

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
  if isHeader(key,value):
    meta["header"] = { "c": value[2], "t": "MetaInlines" }
    return []
  if isFooter(key,value):
    meta["footer"] = { "c": value[2], "t": "MetaInlines" }
    return []

def fix_hr(key, value, format, meta):
  if key == "HorizontalRule":
    return RawBlock('latex', '\\hrulefill')

def fix_pagebreaks(key, value, format, meta):
  if isPageBreak(key,value):
    return RawBlock('latex', '\\pagebreak')

def fix_underline(key, value, format, meta):
  if isUnderline(key,value):
    return [ RawInline('latex', '\\uline{'), Span(value[0], value[1]), RawInline('latex', '}') ]

def toJSONFilter():
  doc = json.loads(sys.stdin.read())
  if len(sys.argv) > 1:
    format = sys.argv[1]
  else:
    format = ""

  # first, process metadata (title and subtitle)
  result_meta = doc[0]['unMeta']
  doc = walk(doc, extract_metadata, format, result_meta)

  # We need a title, use a default if unset
  if 'title' not in result_meta:
      title = {'c': 'Untitled', 't': 'Str'}
      result_meta['title'] = { "c": [title], "t": "MetaInlines" }

  doc[0]['unMeta'] = result_meta

  # then, fix page breaks
  doc = walk(doc, fix_pagebreaks, format, result_meta)

  # then, fix underline
  doc = walk(doc, fix_underline, format, result_meta)

  # then, customize horizontal rules (otherwise they're hardcoded in Writers/LaTeX.hs)
  doc = walk(doc, fix_hr, format, result_meta)

  json.dump(doc, sys.stdout)

if __name__ == "__main__":
  toJSONFilter()
