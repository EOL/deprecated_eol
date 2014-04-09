require "spec_helper"

# TODO - I started writing this to fix a bug, but found that the bug was actually elsewhere.  However, there's enough of a skeleton here that I wanted to
# keep it for future use...

describe 'taxa/media/index' do

  before do
    assign(:taxon_page, double(TaxonPage))
  end

  context 'with media' do

    before do
      assign(:taxon_media, double(TaxonPage))
    end

    it 'has proper metadata'

  end

  context 'with no media' do
    
    it 'includes notice of no media in metadata' do
      pending
    end

  end

end

