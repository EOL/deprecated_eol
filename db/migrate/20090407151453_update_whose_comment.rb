class UpdateWhoseComment < ActiveRecord::Migration
  
  def self.up
    #for old comments marks from_curator as true if author of a comment can curate a object of commenting
    Comment.find(:all).each do |comment|
			comment_user = User.find(comment.user_id)
			comment.parent_type == 'DataObject' ? comment_parent = DataObject.find(comment.parent_id) : comment_parent = TaxonConcept.find(comment.parent_id) 

			this_is_curatable = comment_parent.is_curatable_by?(comment_user)
      
			comment.update_attributes(:from_curator => this_is_curatable) # true, if author of a comment is a curator
    end
  end


  def self.down
    #restore false for all comments!
    Comment.find(:all).each do |comment| 
      comment.update_attributes(:from_curator => false)
    end
  end
end

