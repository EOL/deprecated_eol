describe Hierarchy::Relator do
  let(:hierarchy) { Hierarchy.gen }
  subject { Hierarchy::Relator.new(hierarchy) }

  it 'should skip duplicatre entries'
  it 'should skip entries with no name'
  it 'should skip entries both in complete hierarchies'
  it 'should skip entries that are in incompatible ranks'
  it 'should not compare synonyms if one is a virus'
  it 'should score lowly if one entry has no ancestors'
  it 'should score family ancestor matches highly'
  it 'should score kingdom matches lowly'
  it 'should score class matches moderately'
  it 'should (currently) refuse to run without entry IDs'

  # etc etc, sorry, got bored. :|
end
