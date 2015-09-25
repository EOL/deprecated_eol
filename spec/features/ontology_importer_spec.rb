require "spec_helper"

def stub_ontology_request
  stub_request(:get, "http://some.ontology/").
    to_return(:body =>'<?xml version="1.0" encoding="UTF-8"?>
      <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
        xmlns:dcterms="http://purl.org/dc/terms/">
        <rdf:Description rdf:about="http://some.ontology/termA">
          <rdfs:label xml:lang="en">First term label</rdfs:label>
          <dcterms:description xml:lang="en">First term definition</dcterms:description>
          <rdfs:comment xml:lang="en">First term comment</rdfs:comment>
        </rdf:Description>
        <rdf:Description rdf:about="http://some.ontology/termB">
          <rdfs:label xml:lang="en">Second term label</rdfs:label>
          <dcterms:description xml:lang="en">Second term definition</dcterms:description>
          <rdfs:comment xml:lang="en">Second term comment</rdfs:comment>
        </rdf:Description>
      </rdf:RDF>')
end

def import_ontology(options = {})
  select 'Definition', from: 'dcterms:description'
  select 'Comment', from: 'rdfs:comment'
  find(:css, "table.ontology input[value='http://some.ontology/termA']").set(true)
  find(:css, "table.ontology input[value='http://some.ontology/termB']").set(true)
  if options[:hide_from_glossary]
    check 'known_uri_hide_from_glossary'
  end
  click_button 'Import Ontology'
end

describe 'Ontology Importer' do

  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @user = User.gen
    @user.grant_permission(:see_data)
    @user.grant_admin
  end

  before(:each) do
    KnownUri.destroy_all
    TranslatedKnownUri.destroy_all
    login_as @user
    stub_ontology_request
    # go to the KnownUris page, enter the ontology URL, and click submit
    visit known_uris_path
    fill_in 'ontology_uri', with: 'http://some.ontology'
    click_button 'Import Ontology'
  end

  it 'lists the terms in the ontology' do
    expect(body).to include('Reading from <a href="http://some.ontology" target="_blank">http://some.ontology</a>')
    expect(body).to include('http://some.ontology/termA')
    expect(body).to include('First term label')
    expect(body).to include('First term definition')
    expect(body).to include('First term comment')
    expect(body).to include('http://some.ontology/termB')
    expect(body).to include('Second term label')
    expect(body).to include('Second term definition')
    expect(body).to include('Second term comment')
  end

  it 'imports the terms' do
    import_ontology
    termA = KnownUri.by_uri('http://some.ontology/termA')
    expect(termA).to be_a(KnownUri)
    expect(termA.label(:en)).to eq('First term label')
    expect(termA.definition(:en)).to eq('First term definition')
    expect(termA.comment(:en)).to eq('First term comment')
    expect(termA.hide_from_glossary).to eq(false)
    termB = KnownUri.by_uri('http://some.ontology/termB')
    expect(termB).to be_a(KnownUri)
    expect(termB.label(:en)).to eq('Second term label')
    expect(termB.definition(:en)).to eq('Second term definition')
    expect(termB.comment(:en)).to eq('Second term comment')
    expect(termB.hide_from_glossary).to eq(false)
  end

  it 'imports with a hide_from_glossary flag' do
    import_ontology(hide_from_glossary: true)
    termA = KnownUri.by_uri('http://some.ontology/termA')
    expect(termA.hide_from_glossary).to eq(true)
    termB = KnownUri.by_uri('http://some.ontology/termB')
    expect(termB.hide_from_glossary).to eq(true)
  end

end
