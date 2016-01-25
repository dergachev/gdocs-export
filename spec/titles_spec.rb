require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_titles' do
  it "annotates a single title" do
    preproc = PandocPreprocess.new('<p class="title">foo</p>')
    preproc.fixup_titles

    expect(preproc.doc.css('p').size).to eq 0
    expect(preproc.doc.css('h1').size).to eq 1

    h1 = preproc.doc.at('h1')
    expect(h1['class']).to eq 'ew-pandoc-title'
    expect(h1.text).to eq 'foo'
  end
end
