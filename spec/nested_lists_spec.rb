require 'preprocess'

require 'rubygems'
require 'nokogiri'

RSpec.describe PandocPreprocess, '#fixup_lists' do
  it "does nothing if there are no lists" do
    preproc = PandocPreprocess.new(Nokogiri::HTML('<div>foo</div>'))
    preproc.fixup_lists
    expect(preproc.doc.at('body').inner_html).to eq '<div>foo</div>'
  end

  it "coalesces consecutive lists" do
    preproc = PandocPreprocess.new(Nokogiri::HTML(<<EOF))
      <ul class="lst-kix_xxx-0">
        <li>foo</li>
      </ul>
      <ul class="lst-kix_xxx-0">
        <li>bar</li>
      </ul>
EOF
    preproc.fixup_lists
    expect(preproc.doc.css('body > ul').size).to eq 1
    expect(preproc.doc.css('body > ul > li').size).to eq 2
    expect(preproc.doc.css('body > ul > li')[1].inner_text).to eq 'bar'
  end

  it "moves sublists into place" do
    preproc = PandocPreprocess.new(Nokogiri::HTML(<<EOF))
      <ul class="lst-kix_xxx-0">
        <li>foo</li>
      </ul>
      <ul class="lst-kix_xxx-1">
        <li>bar</li>
      </ul>
EOF
    preproc.fixup_lists
    expect(preproc.doc.css('body > ul').size).to eq 1
    expect(preproc.doc.css('body > ul > li').size).to eq 1
    inner = preproc.doc.css('body > ul > li > ul')
    expect(inner.size).to eq 1
    expect(inner.first.inner_text.strip).to eq 'bar'
  end

  it "coalesces consecutive lists" do
    preproc = PandocPreprocess.new(Nokogiri::HTML(<<EOF))
      <ul class="lst-kix_xxx-0">
        <li>foo</li>
      </ul>
      <ul class="lst-kix_xxx-1">
        <li>iggy</li>
      </ul>
      <ul class="lst-kix_xxx-0">
        <li>bar</li>
      </ul>
EOF
    preproc.fixup_lists
    doc = preproc.doc
    expect(doc.css('body > ul').size).to eq 1
    expect(doc.css('body > ul > li').size).to eq 2
    expect(doc.css('body > ul > li')[1].inner_text).to eq 'bar'

    inner = doc.css('body > ul > li > ul')
    expect(inner.size).to eq 1
    expect(inner.first.inner_text.strip).to eq 'iggy'
  end


  it "handles realistic input" do
    preproc = PandocPreprocess.new(Nokogiri::HTML(<<EOF))
    <p class="c0">
      <span>p1</span>
    </p>
    <p class="c0 c2"></p>
    <p class="c0">
      <span>p2</span>
    </p>
    <p class="c0 c2"></p>
    <ul class="c1 lst-kix_3n5d5m4s86b4-0 start">
      <li class="c0 c4">
        <span>foo</span>
      </li>
      <li class="c0 c4">
        <span>bar</span>
      </li>
    </ul>
    <ul class="c1 lst-kix_3n5d5m4s86b4-1 start">
      <li class="c0 c6">
        <span>iggy</span>
      </li>
    </ul>
    <ul class="c1 lst-kix_3n5d5m4s86b4-2 start">
      <li class="c0 c3">
        <span>baz</span>
      </li>
      <li class="c0 c3">
        <span>qux</span>
      </li>
    </ul>
    <ul class="c1 lst-kix_3n5d5m4s86b4-1">
      <li class="c0 c6">
        <span>blah</span>
      </li>
    </ul>
    <ul class="c1 lst-kix_3n5d5m4s86b4-0">
      <li class="c0 c4">
        <span>aaa</span>
      </li>
      <li class="c0 c4">
        <span>bbb</span>
      </li>
    </ul>
    <ul class="c1 lst-kix_3n5d5m4s86b4-1 start">
      <li class="c0 c6">
        <span>ccc</span>
      </li>
    </ul>
    <p class="c0 c2"></p>
    <p class="c0">
      <span>p2</span>
    </p>
    <p class="c0 c2"></p>
    <ol class="c1 lst-kix_s0nh1lcbjots-0 start" start="1">
      <li class="c0 c4">
        <span>ccc</span>
      </li>
    </ol>
    <ol class="c1 lst-kix_s0nh1lcbjots-1 start" start="1">
      <li class="c0 c6">
        <span>ddd</span>
      </li>
    </ol>
    <ol class="c1 lst-kix_s0nh1lcbjots-0" start="2">
      <li class="c0 c4">
        <span>eee</span>
      </li>
    </ol>
    <p class="c0 c2"></p>
    <p class="c0 c2"></p>
    <p class="c0 c2"></p>
    <p class="c0">
      <span>fdfafdaf</span>
    </p>
EOF

    # Target result with all attributes stripped, whitespace changes ok
    target = <<EOF.gsub(/(>|^)?\s+(<|$)/, '\1\2')
      <p><span>p1</span></p><p></p>
      <p><span>p2</span></p><p></p>
      <ul>
        <li><span>foo</span></li>
        <li><span>bar</span><ul>
          <li><span>iggy</span><ul>
            <li><span>baz</span></li>
            <li><span>qux</span></li>
          </ul></li>
          <li><span>blah</span></li>
        </ul></li>
        <li><span>aaa</span></li>
        <li><span>bbb</span><ul>
          <li><span>ccc</span></li>
        </ul></li>
      </ul>
      <p></p><p><span>p2</span></p><p></p>
      <ol>
        <li><span>ccc</span><ol>
          <li><span>ddd</span></li>
        </ol></li>
        <li><span>eee</span></li>
      </ol>
      <p></p><p></p><p></p><p><span>fdfafdaf</span></p>
EOF

    preproc.fixup_lists
    body = preproc.doc.at('body')

    # Remove attributes, strip space
    body.xpath('//*').each do |e|
      e.attributes.keys.each { |k| e.remove_attribute(k) }
    end
    result = body.inner_html.gsub(/(>|^)?\s+(<|$)/, '\1\2')

    expect(result).to eq target
  end
end

