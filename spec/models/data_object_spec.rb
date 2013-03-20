require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../scenario_helpers'

describe Association do

  before(:all) do
    # I'm sure I'll need it...
  end

  describe 'for a content-partner submitted object' do

    it 'should know its data object'
    it 'should know its taxon concept'
    # ?? Really, should it? -> it 'should know its hierarchy' 

  end

  describe 'for a user-submitted object' do
    it 'should know its data object'
    it 'should know its taxon concept'
  end

  it 'should be created with a user, data object, and hierarchy entry'
  it 'should be removable with a user, data object, and hierarchy entry'
  it 'should check existence between data object and taxon concept'
  it 'should be able to add a relationship by a user'

  # ? it 'should know its name'
  it 'should know if it was added by a curator'
  it 'should know if it was added by a user'
  it 'should know its vetted state'
  it 'should know its visibility'
  it 'should be hidable'
  it 'should be showable'
  it 'should be trustable'
  it 'should be untrustable'
  it 'should be unreviewable' # Errr.... unreviewed-able?
  # ? it 'should know any reasons given for hiding'
  # ? it 'should know any reasons given for untrusting'
  
  describe 'when in preview state' do

    it 'should not be curatable'

  end
  
end

