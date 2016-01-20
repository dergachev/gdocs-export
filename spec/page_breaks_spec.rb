require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_page_breaks' do
  it "replaces a single page break with h1" do
    preproc = PandocPreprocess.new(
      '<hr style="page-break-before:always;display:none;"/>')
    preproc.fixup_page_breaks
    expect(preproc.doc.css('hr').size).to eq 0
    expect(preproc.doc.css('h1').size).to eq 1
    expect(preproc.doc.at('h1')['class']).to eq 'ew-pandoc-pagebreak'
  end
end
