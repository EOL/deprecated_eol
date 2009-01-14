require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do

  fixtures :roles
  
  it '#create_valid should be valid' do
    lambda { Comment.create_valid.should be_valid }.should change(Comment, :count).by(1)
  end

  it 'should be able to comment on a DataObject' do
    bob    = User.create_valid
    object = DataObject.first || DataObject.create_valid

    bob.comments.should be_empty
    object.comments.should be_empty

    comment = object.comment bob, "I liked this object"
    comment.should be_valid

    object.comments.should include(comment)
    bob.comments.should include(comment)
    bob.comments.first.body.should == "I liked this object"
  end

  it 'should be able to comment on a TaxonConcept' do
    bob    = User.create_valid
    concept = TaxonConcept.first # || TaxonConcept.create_valid # <-- don't have this yet!!!!!!  need a TaxonConcept spec!!!!!!!!
    concept.should_not be_nil

    bob.comments.should be_empty
    concept.comments.should be_empty

    comment = concept.comment bob, "I liked this concept"
    comment.should be_valid

    concept.comments.should include(comment)
    bob.comments.should include(comment)
    bob.comments.first.body.should == "I liked this concept"
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: comments
#
#  id          :integer(4)      not null, primary key
#  parent_id   :integer(4)      not null
#  user_id     :integer(4)
#  body        :text            not null
#  parent_type :string(255)     not null
#  created_at  :datetime
#  updated_at  :datetime
#  visible_at  :datetime

