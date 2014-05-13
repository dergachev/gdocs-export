#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'

require 'open-uri'

@source = ARGF.read

@doc = Nokogiri::HTML(@source)

# download all referenced images (they have absolute URLs)
@doc.css("img").each do |x|
  uri = x['src']
  name = File.basename(uri)
  name_with_ext = "#{name}.jpg"
  path = "./#{name_with_ext}"
  unless File.exists?(path)
    File.open(path,'wb'){ |f| f.write(open(uri).read) }
  end
  x['src'] = "#{name_with_ext}"
end


# support Google Docs title format, this prepares it for extract_metadata
@doc.css("p.title").each do |x|
  x.replace("<h1 class='ew-pandoc-title'>#{x.content}</h1>")
end

# support Google Docs subtitle format; this prepares it for extract_metada
@doc.css("p.subtitle").each do |x|
  x.replace("<h1 class='ew-pandoc-subtitle'>#{x.content}</h1>")
end

# fix bold tags; in the source:
#  .c14{font-weight:bold}
#  <span class="c14">Bold Text </span>
bold_classes = @source.scan(/\.(c\d+)\{font-weight:bold\}/)
bold_classes.each do |cssClass|
  @doc.css("span.#{cssClass[0]}").each do |x|
    x.replace("<strong>#{x.content}</strong>")
  end
end

# fix italic tags; in the source:
#  .c16{font-style:italic}
#  <span class="c16">Italic Text</span>
@source.scan(/\.(c\d+)\{font-style:italic\}/).each do |cssClass|
  @doc.css("span.#{cssClass[0]}").each do |x|
    x.replace("<em>#{x.content}</em>")
  end
end

# fix underline tags; in the source:
#  .c13{text-decoration: underline}
#  <span class="c13">Underline Text</span>
#  Because pandoc doesn't support <u>, we make it into h1.underline
#  and rely on custom filtering to convert to LaTeX properly.
@source.scan(/\.(c\d+)\{text-decoration:underline\}/).each do |cssClass|
  @doc.css("span.#{cssClass[0]}").each do |x|
    # x.replace("<h1 class='underline'>#{x.content}</h1>")
    # x.replace("<s>#{x.content}</s>")
    x.replace("<span class='underline'>#{x.content}</s>")
  end
end

# sometimes images are placed inside a heading tag, which crashes latex
@doc.css('h1,h2,h3,h4,h5,h6').>('img').each do |x|
  x.parent.replace(x)
end

@doc.css('div').each do |x|
  # header: first div in body
  if (!x.previous_sibling && !x.previous_element)
    x.replace("<h1 class='ew-pandoc-header'>#{x.inner_text}</h1>")
  end

  # footer: last div in body
  if (!x.next_sibling && !x.next_element)
    x.replace("<h1 class='ew-pandoc-footer'>#{x.inner_text}</h1>")
  end
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

html = @doc.to_html
puts html

# trying to fix encoding bug introduced by ruby1.9.3 or nokogori 1.6
# &nbsp; are converted to strange characters, instead of staying as they are
# puts @doc.to_html.encode('utf-8')
# puts @doc.to_html.encode('iso-8859-1').encode('utf-8')
# nbsp = Nokogiri::HTML("&nbsp;").text
# html.gsub(nbsp, "&nbsp;")


# TODO: ensure neither title or subtitle occur more than once, or are empty
# TODO: write some tests
