require "spec_helper"

describe Enumerated do

  it 'should handle simple arrays' do
    SpecialCollection.delete_all
    SpecialCollection.create_enumerated
    SpecialCollection.enumerations.each do |enum, val|
      expect(SpecialCollection.send(enum).name).to eq(val)
    end
  end

  it 'should handle a translated enumerated class' do
    ViewStyle.delete_all
    TranslatedViewStyle.delete_all
    ViewStyle.create_enumerated
    ViewStyle.enumerations.each do |enum, val|
      expect(ViewStyle.send(enum).name).to eq(val)
    end
  end

  # NOTE that this could potentially go stale and not actually be testing anything useful.  :\
  it 'should handle hashes' do
    MimeType.delete_all
    TranslatedMimeType.delete_all
    MimeType.create_enumerated
    MimeType.enumerations.each do |enum, val|
      expect(MimeType.send(enum).label).to eq(val)
    end
  end

end
