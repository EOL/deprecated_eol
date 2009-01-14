require File.dirname(__FILE__) + '/../spec_helper'

describe Comment, 'curation' do

  fixtures :roles

  before(:all) do
    # delete all TopImage associations so they don't interfere with our associations
    TopImage.delete_all
  end

  before(:each) do
    @bob   = User.create_valid!
    @object = create_dataobject_in_clade 16222828 # cafeteria, it's under Chromista (16101659)
    @comment = @object.comment @bob, 'This object is neato'
  end

  it 'should allow curation of the h_e the user has approval for' do
    # @object.should_receive(:hierarchy_entries_with_parents).and_return(
    @bob.approve_to_curate! 16222828
    @bob.can_curate?(@comment).should be_true
  end

  it 'should allow curation of a h_e within the clade a user has approval for' do
    @bob.approve_to_curate! 16101659 # Chromista
    @bob.can_curate?(@comment).should be_true
  end

  it 'should NOT allow curation of a h_e not in the clade a user has approval for' do
    @bob.approve_to_curate! 16103368 # a different branch (Viruses) of the tree, NOT above cafeteria
    @bob.can_curate?(@comment).should be_false
  end

  it "shouldn't be able to curate data object comments (if not approved)" do
    @bob.can_curate?(@comment).should be_false
  end

  it 'should be able to curate taxon concept comments (if approved)' do
    @bob.approve_to_curate! 16222828
    @bob.can_curate?(@comment).should be_true

    @bob.approve_to_curate! 16103368 # a different branch (Viruses) of the tree, NOT above cafeteria
    @bob.can_curate?(@comment).should be_false

    @bob.approve_to_curate! 16101659 # Chromista
    @bob.can_curate?(@comment).should be_true
  end

  it "shouldn't be able to curate taxon concept comments (if not approved)" do
    @bob.can_curate?(@comment).should be_false
    @bob.can_curate?(@comment).should be_false
    @bob.can_curate?(@comment).should be_false
  end

  # SHOULD AFFECT VISIBLE_COMMENTS!!!!!!!!!!!!!!!!!
  
  it 'should not be able to vet comments it cannot curate' do
    @comment.unvet!

    curator_guy = User.create_valid! :username => 'curator', :email => 'curator@guy.com'
    curator_guy.vet @comment
    @comment.should_not be_vetted
  end

  it 'should be able to vet comments it can_curate?' do
    @comment.unvet!

    curator_guy = User.create_valid! :username => 'curator', :email => 'curator@guy.com'

    curator_guy.approve_to_curate! 16222828
    curator_guy.vet @comment
    @comment.should be_vetted
    curator_guy.unvet @comment
    @comment.should_not be_vetted
  end

  it 'vetting comments should change @object.visible_comments(user)'

  it 'should not be able to vet comments it cannot curate'

  ### NEXT : make an observer for Comment !!!! ###

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

