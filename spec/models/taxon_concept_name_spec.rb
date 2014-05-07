# encoding: utf-8
require "spec_helper"

describe TaxonConceptName do

  before :all do
    load_foundation_cache
    @preferred = TaxonConceptName.gen(preferred: 1)
  end

  it 'should remove preferred flag after untrusting a name' do
    @preferred.preferred.should == 1
    @preferred.vet(Vetted.untrusted, User.gen)
    @preferred.reload # TODO - perhaps we should actually update the instance after updating the table, eh?  :|
    @preferred.preferred.should == 0
  end

end
