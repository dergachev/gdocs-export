#!/usr/bin/env ruby

require_relative 'include/preprocess'

html = ARGF.read
preproc = PandocPreprocess.new(html)
preproc.process
preproc.download_resources
puts preproc.doc.to_html(encoding: 'ASCII')
