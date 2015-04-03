require "spec_helper"

describe TaxonDataExemplarPicker do

  before(:all) do
    Visibility.create_enumerated
    @known_uri_1 = build_stubbed(KnownUri)
    @shown = build_stubbed(Trait, visibility: Visibility.visible, predicate_known_uri: @known_uri_1)
    @hidden = build_stubbed(Trait, visibility: Visibility.invisible, predicate_known_uri: @known_uri_1)
    @taxon_concept = build_stubbed(TaxonConcept)
  end

  before do # You can't call #double from before_all
    @taxon_data = double(TaxonData, taxon_concept: @taxon_concept, get_data: [@shown, @hidden])
    @picker = TaxonDataExemplarPicker.new(@taxon_data)
    @picked = @picker.pick
  end

  it 'removes hidden data' do
    expect(@picked).to_not include(@hidden)
  end

  it 'shows normal data' do
    expect(@picked).to include(@shown)
  end

end
