require File.dirname(__FILE__) + '/../spec_helper'

describe User, 'curation' do

  fixtures :roles

  before do
    # delete all TopImage associations so they don't interfere with our associations
    TopImage.delete_all
  end

=begin
# snippet of HierarchyEntries (from fixtures) for reference

[16097869] Animals [1 -> 126]
  [99901] common porro [2 -> 3]
  [99902] Rudolph's est [4 -> 5]
  [99903] giant excepturi [6 -> 7]
  [888001] Karenteen seabream [124 -> 125]
[16098238] Plants [127 -> 128]
[16098245] Bacteria [129 -> 130]
[16101659] Chromista [131 -> 146]
  [16101973] <i>Sagenista</i> [132 -> 145]
    [16101974] Bicosoecids [133 -> 144]
      [16101975] <i>Bicosoecales</i> [134 -> 143]
        [16101978] <i>Cafeteriaceae</i> [135 -> 142]
          [16109089] <i>Cafeteria</i> [136 -> 139]
            [16222828] <i>Cafeteria roenbergensis</i> [137 -> 138]
          [16222829] <i>Spicy Food</i> [140 -> 141]
[16101981] Fungi [147 -> 148]
[16103012] Protozoa [149 -> 150]
[16103368] Viruses [151 -> 152]
[16106613] Archaea [153 -> 154]

=end

  it 'should be able to curate hierarchy entries (if approved)' do
    bob   = User.create_valid!
    clade = HierarchyEntry.first

    bob.approve_to_curate! clade

    bob.can_curate?(clade).should     be_true
    bob.is_curator_for?(clade).should be_true
  end

  it 'should not be able to curate hierarchy entries (if not approved)' do
    bob   = User.create_valid!
    clade = HierarchyEntry.first

    bob.can_curate?(clade).should     be_false
    bob.is_curator_for?(clade).should be_false
  end

  it 'should be able to curate data objects (if approved)' do
    bob    = User.create_valid!
    object = create_dataobject_in_clade 16222828 # cafeteria, it's under Chromista (16101659)

    bob.approve_to_curate! 16222828
    bob.can_curate?(object).should be_true

    bob.approve_to_curate! 16103368 # a different branch (Viruses) of the tree, NOT above cafeteria
    bob.can_curate?(object).should be_false

    bob.approve_to_curate! 16101659 # Chromista
    bob.can_curate?(object).should be_true
  end

  it 'should be not able to curate data objects (if not approved)' do
    bob    = User.create_valid!
    object = create_dataobject_in_clade 16222828 # cafeteria, it's under Chromista (16101659)

    bob.can_curate?(object).should be_false
  end

  it 'should be able to vet & unvet data objects it can_curate?' do
    object = create_dataobject_in_clade 16222828
    object.unvet!
    object.should_not be_vetted
    
    bob = User.create_valid!
    bob.approve_to_curate! 16101978 # this is _above_ 16222828 (which we'll assign data object to)
    bob.vet object
    object.should be_vetted
  end

  it 'should not be able to vet data objects it cannot curate' do
    object = create_dataobject_in_clade 16222828
    object.unvet!
    object.should_not be_vetted

    bob = User.create_valid!
    bob.vet object
    object.should_not be_vetted
  end

  it 'should not require a curation verdict regardless of whether or not curation request hierarchy entry id is set' # ???

end
