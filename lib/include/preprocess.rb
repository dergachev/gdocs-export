require 'nokogiri'
require 'open-uri'

class PandocPreprocess
  attr_reader :doc, :downloads
  def initialize(html)
    @source = html
    @doc = Nokogiri::HTML(html)
    @downloads = {}
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
      @source.scan(/\.(c\d+)\{#{style}\}/).each do |cssClass,|
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
end
