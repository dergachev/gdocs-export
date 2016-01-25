require 'preprocess'

RSpec.describe PandocPreprocess, '#fixup_image_paths' do
  it "finds a single img" do
    preproc = PandocPreprocess.new('<img src="foo"/>')
    preproc.fixup_image_paths
    expect(preproc.downloads.size).to eq 1
    expect(preproc.downloads).to include('foo.jpg')
    expect(preproc.downloads['foo.jpg']).to eq 'foo'
    expect(preproc.doc.at('img')['src']).to eq 'foo.jpg'
  end
end
