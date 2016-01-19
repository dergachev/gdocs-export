class PandocPreprocess
  attr_reader :doc
  def initialize(doc)
    @doc = doc
  end

  # Get the zero-based depth of a list
  def list_depth(list)
    klasses = list['class'] or return 0
    klass = klasses.split.each do |klass|
      md = /^lst-kix_.*-(\d+)/.match(klass) or next
      return md[1].to_i
    end
    return 0
  end

  def fixup_lists
    # Google Docs exports nested lists as separate lists next to each other.

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
        prev = list.previous
        next unless %w[ol ul].include?(prev.name)

        # p [depth, list_depth(prev)]
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
end
