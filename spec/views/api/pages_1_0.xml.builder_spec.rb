require "spec_helper"

describe 'api/pages_1_0.xml.builder' do

  before do
    @json_response = {'identifier' => 15,
      'scientificName' => "SciName",
      'synonyms' => [{'synonym' => 'Syn1', 'relationship' => 'mom'}, {'synonym' => 'Syn2', 'relationship' => 'dad'}],
      'vernacularNames' => [],
      'references' => [],
      'richness_score' => 24,
      'taxonConcepts' => [],
      # Fun.  :|
      'dataObjects' => [{'identifier' => 67, 'dataType' => 'Doubtful', 'agents' => [],
        
      }]
    }
  end

  it 'renders XML' do
    render
    expect(rendered).to match /XML/
  end
  
  it 'renders a data object' do
    render
    expect(rendered).to match /<dataObjectID>67<\/dataObjectID>/
  end

end
