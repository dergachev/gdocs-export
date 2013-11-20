#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'

@doc = Nokogiri::HTML(ARGF.read)

@doc.css("p.title").each do |x|
  x.replace("<h1 class='ew-pandoc-title'>#{x.content}</h1>")
end

@doc.css("p.subtitle").each do |x|
  x.replace("<h1 class='ew-pandoc-subtitle'>#{x.content}</h1>")
end


# remove empty nodes (google docs has lots of them, especially with pagebreaks)
# must come before pagebreak processing
@doc.css('h1,h2,h3,h4,h5,h6').each do |x|
  x.remove if x.content =~ /^\s*$/
end

# Rewrite page breaks into something pandoc can parse
# <hr style="page-break-before:always;display:none;">
@doc.css('hr[style="page-break-before:always;display:none;"]').each do |x|
  x.replace("<h1 class='ew-pandoc-pagebreak' />")
end

puts @doc.to_html


# TODO: ensure neither title or subtitle occur more than once, or are empty
# TODO: write some tests
