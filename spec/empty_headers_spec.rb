require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_empty_headers' do
  it "removes a single empty h1" do
    preproc = PandocPreprocess.new('<h1></h1>')
    preproc.fixup_empty_headers
    expect(preproc.doc.css('h1').size).to eq 0
  end
end
