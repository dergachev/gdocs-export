require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_headers_footers' do
  it "turns the first div into a header" do
    preproc = PandocPreprocess.new('<div>foo</div>')
    preproc.fixup_headers_footers
    expect(preproc.doc.css('h1').size).to eq 1
    expect(preproc.doc.at('h1')['class']).to eq 'ew-pandoc-header'
    expect(preproc.doc.css('div').size).to eq 0
  end
end
