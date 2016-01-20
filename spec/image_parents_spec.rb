require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_image_parents' do
  it "unwraps an h1 containing an img" do
    preproc = PandocPreprocess.new('<h1><img src="foo.png"/></h1>')
    preproc.fixup_image_parents
    expect(preproc.doc.css('h1').size).to eq 0
    expect(preproc.doc.css('body > img').size).to eq 1
  end
end
