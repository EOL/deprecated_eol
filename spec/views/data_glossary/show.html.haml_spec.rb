require "spec_helper"

def create_measurement_for_uri(known_uri)
  DataMeasurement.new(subject: TaxonConcept.gen, resource: Resource.gen,
    predicate: known_uri.uri, object: 'whatever').update_triplestore
end

describe 'data_glossary/show' do

  before(:all) do
    load_foundation_cache
    @user = User.gen
    @user.grant_permission(:see_data)
  end

  before(:each) do
    view.stub(:current_user) { @user }
    view.stub(:current_language) { Language.default }
  end

  it 'only shows measurement URIs which have measurement records' do
    new_uri = KnownUri.gen_if_not_exists(name: 'Some New Uri')
    render
    # it should not show up yet because there are no measurements using it
    expect(rendered).to_not match(new_uri.name)
    create_measurement_for_uri(new_uri)
    Rails.cache.clear
    render
    expect(rendered).to match(new_uri.name)
  end

  it 'does not show URIs which are hidden from the glossary' do
    new_uri = KnownUri.gen_if_not_exists(name: 'Another New Uri')
    create_measurement_for_uri(new_uri)
    render
    expect(rendered).to match(new_uri.name)
    new_uri.update_column(:hide_from_glossary, true)
    Rails.cache.clear
    rendered = render
    expect(rendered).to_not match(new_uri.name)
  end

end
