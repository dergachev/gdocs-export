#!/usr/bin/env ruby

require_relative 'include/preprocess'

html = ARGF.read
preproc = PandocPreprocess.new(html)
preproc.process
puts preproc.doc.to_html
