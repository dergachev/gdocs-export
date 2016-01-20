require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_span_styles' do
  it "replaces a bold class with a strong" do
    preproc = PandocPreprocess.new(<<EOF)
      <head>
        <style>
          .c14{font-weight:bold}
        </style>
      </head>
      <body>
        <span class="c14">foo</span>
      </body>
EOF
    preproc.fixup_span_styles
    expect(preproc.doc.css('span').size).to eq 0
    expect(preproc.doc.css('strong').size).to eq 1
    expect(preproc.doc.css('strong').text).to eq 'foo'
  end
end
