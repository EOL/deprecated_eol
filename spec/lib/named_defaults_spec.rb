require 'spec_helper'

# NOTE - this class uses metaprogramming, which is too hard to test directly, so here I'm just testing that what we directly care
# about is actually true...
describe NamedDefaults do

  it 'should create all the correct licenses' do
    License.create_defaults
    License.default_values.each do |default|
      this = License.send(default[:method_name])
      expect(this).to_not be_nil
      expect(this.title).to eq(default[:title].to_s)
      expect(this.description).to eq(default[:description].to_s)
    end
  end

  it 'should create all the correct known URIs' do
    # I just happen to know that the defaluts for KURI need most of these...
    UriType.create_defaults
    Vetted.create_defaults
    Visibility.create_defaults
    KnownUri.create_defaults
    KnownUri.default_values.each do |default|
      this = KnownUri.send(default[:method_name])
      expect(this).to_not be_nil
      expect(this.name).to eq(default[:name].to_s)
      expect(this.uri).to eq(default[:uri].to_s)
      if default.has_key?(:uri_type_id)
        expect(this.uri_type.id).to eq(default[:uri_type_id])
      else
        expect(this.uri_type).to eq(UriType.value)
      end
    end
  end

end
