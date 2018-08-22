require 'nokogiri'
require 'open-uri'
require 'css_parser'

class PandocPreprocess
  attr_reader :doc, :downloads
  def initialize(html)
    @source = html
    @doc = Nokogiri::HTML(html)
    @doc.encoding = 'UTF-8'
    @style_sheet = @doc.at_css("style").inner_text
    @downloads = {}

    $style_sheet = @doc.at_css("style").inner_text
    $parsed_style_sheet = CssParser::Parser.new
    $parsed_style_sheet.load_string!(@style_sheet)
  end

  def download_resources
    @downloads.each do |path, src|
      open(path, 'w') { |f| open(src) { |img| f.write(img.read) }}
    end
  end

  def html
    @doc.to_html
  end

  def process
    validate
    fixup_image_paths
    fixup_image_parents
    fixup_titles
    fixup_span_styles
    fixup_headers_footers
    fixup_empty_headers
    fixup_page_breaks
    fixup_lists
    fixup_image_attributes
    add_colgroup_to_tables
  end

  # Replace remote with local images
  # All image srcs have absolute URLs
  def fixup_image_paths
    doc.css("img").each do |x|
      uri = x['src']
      name = File.basename(uri)
      name_with_ext = "#{name}.jpg"
      @downloads[name_with_ext] = uri
      x['src'] = name_with_ext
    end
  end

  # Sometimes images are placed inside a heading tag, which crashes latex
  def fixup_image_parents
    doc.css('h1,h2,h3,h4,h5,h6').>('img').each do |x|
      x.parent.replace(x)
    end
  end

  # Support Google Docs title format, this prepares it for extract_metadata
  def fixup_titles
    # TODO: ensure neither title or subtitle occur more than once, or are empty
    %w[title subtitle].each do |type|
      doc.css("p.#{type}").each do |x|
        x.replace("<h1 class='ew-pandoc-#{type}'>#{x.text}</h1>")
      end
    end
  end

  def fixup_span_styles
    # Source has, eg:
    #  .c14{font-weight:bold}
    #  <span class="c14">Bold Text </span>
    #
    # Because pandoc doesn't support <u>, we make it into h1.underline
    # and rely on custom filtering to convert to LaTeX properly.
    styles = {
      'font-weight:bold' => 'strong',
      'font-weight:700' => 'strong',
      'font-style:italic' => 'em',
      'text-decoration:underline' => { class: 'underline' },
    }

    styles.each do |style, repl|
      @source.scan(/\.(c\d+)\{([^}]+;)*#{style}[;}]/).each do |cssClass,|
        @doc.css("span.#{cssClass}").each do |x|
          if Hash === repl
            x.replace("<span class='#{repl[:class]}'>#{x.content}</span>")
          else
            x.name = repl
          end
        end
      end
    end
  end

  # Replace first/last div with header/footer.
  def fixup_headers_footers
    @doc.css('div').each do |x|
      # header: first div in body
      if (!x.previous_sibling && !x.previous_element)
        x.replace("<h1 class='ew-pandoc-header'>#{x.inner_text}</h1>")
        next
      end

      # footer: last div in body
      if (!x.next_sibling && !x.next_element)
        x.replace("<h1 class='ew-pandoc-footer'>#{x.inner_text}</h1>")
      end
    end
  end

  # Remove empty nodes: Google Docs has lots of them, especially with
  # pagebreaks.
  def fixup_empty_headers
    # must come before pagebreak processing
    doc.css('h1,h2,h3,h4,h5,h6').each do |x|
      x.remove if x.text =~ /^\s*$/
    end
  end

  # Rewrite page breaks into something pandoc can parse
  def fixup_page_breaks
    # <hr style="page-break-before:always;display:none;">
    doc.css('hr[style="page-break-before:always;display:none;"]').each do |x|
      x.replace("<h1 class='ew-pandoc-pagebreak' />")
    end
  end

  # Get the zero-based depth of a list
  def list_depth(list)
    klasses = list['class'] or return 0
    klass = klasses.split.each do |klass|
      md = /^lst-kix_.*-(\d+)$/.match(klass) or next
      return md[1].to_i
    end
    return 0
  end

  # Google Docs exports nested lists as separate lists next to each other.
  def fixup_lists
    # Pass 1: Figure out the depth of each list
    depths = []
    @doc.css('ul, ol').each do |list|
      depth = list_depth(list)
      (depths[depth] ||= []) << list
    end

    # Pass 2: In reverse-depth order, coalesce lists
    depths.to_enum.with_index.reverse_each do |lists, depth|
      next unless lists
      lists.reverse_each do |list|
        # If the previous item is not a list, we're fine
        prev = list.previous_element
        next unless prev && prev.respond_to?(:name) &&
          %w[ol ul].include?(prev.name)

        if list_depth(prev) == depth
          # Same depth, append our li's to theirs
          prev.add_child(list.children)
          list.remove
        else
          # Lesser depth, append us to their last item
          prev.xpath('li').last.add_child(list)
        end
      end
    end
  end

  # Detect problems before we try to convert this doc
  def validate
    @errors = []
    validate_colspan
    unless @errors.empty?
      STDERR.puts 'Validation errors, bailing'
      @errors.each { |e| STDERR.puts e }
      exit 1
    end
  end

  # Detect colspan > 1
  def validate_colspan
    @doc.css('*[colspan]').
        select { |e| e.attr('colspan').to_i > 1 }.each do |e|
      found = true
      short = e.text[0, 30]
      @errors << "Colspan > 1 for \"#{short}\""
    end
  end
  # Add width and height attributes to images.
  def fixup_image_attributes
    doc.css("img").each do |img|
      style = img.attr('style')
      %w[height width].each do |att|
        val = style.match(/#{att}\s*:\s*([\d.]+)px/)[1]
        img.set_attribute(att, val)
      end
    end
  end
  # Adds a colgroup that includes col tags with a relative width attribute, to all tables. Necessary in order to be parsed by Pandoc.
  def add_colgroup_to_tables
    @doc.css("table").map {|t| GdocTable.new(t)}.each &:prepend_colgroup
  end
end

# Class to simplify dealing with HTML tables
class HtmlTable
  attr_accessor :table, :index, :size
  def initialize(html_table)
    @table = html_table
    table_cells_index
  end
  def table_cells_index
    result = Hash.new
    i = 0
    width = 0
    @table.search("tr").each do |tr|
      j = 0
      tr.search("td").each do |td|
        result[[i, j]] = td
        j += 1
      end
      width = [width, j].max
      i += 1
    end
    height = i
    @size = [height, width]
    @index = result
    result
  end
  def css_classes_index
    @css_classes_index ||= @index.map { |k, v| [k, v.attributes["class"].value] }.to_h
  end
  def css_classes
    @css_classes ||= css_classes_index.map { |_, v| v }.uniq
  end
  def self.h_to_a(h)
    out = []
    h.each do |k, v|
      i = k[0]
      j = k[1]
      out[i] ||= []
      out[i][j] = v
    end
    out
  end
end

# More specialized HTML tables class to deal with how Google-Docs formats tables
class GdocTable < HtmlTable
  attr_reader :parsed_style_sheet
  def initialize(html_table)
    super
    @parsed_style_sheet = $parsed_style_sheet
  end
  def width_by_class
    @width_by_class ||= css_classes.map do |c|
      width_regex = /width:\s*([\d.]{2,})(px|pt)/
      rule_set = parsed_style_sheet.find_by_selector(".#{c}").first
      width = rule_set.match(width_regex)[1] || 0
      [c, width]
    end.to_h
  end
  def width_by_cell
    @width_by_cell ||= self.css_classes_index.map do |k, v|
      [k, width_by_class[v]]
    end.to_h
  end
  def width_by_column
    @width_by_column ||= HtmlTable::h_to_a(width_by_cell).transpose.map { |col| col.map{|x| x.to_f}.max }
  end
  def relative_width_by_column
    total = width_by_column.sum
    @relative_width_by_column ||= width_by_column.map {|x| x/total}
  end
  def colgroup_statement
    out = "<colgroup>"
    relative_width_by_column.each do |w|
      out += "<col width=\"#{sprintf('%.2f', w*100)}%\" />"
    end
    out += "</colgroup>"
  end
  def prepend(str)
    @table.inner_html = str + @table.inner_html
  end
  def prepend_colgroup
    prepend(self.colgroup_statement)
  end
end
