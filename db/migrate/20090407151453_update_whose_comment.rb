class UpdateWhoseComment < ActiveRecord::Migration
  
  def self.up
    #for old comments marks from_curator as true if author of a comment can curate a object of commenting
    Comment.find(:all).each do |comment|
			cu = User.find_by_id(comment.user_id)
			comment.parent_type == 'DataObject' ? ob = DataObject.find_by_id(comment.parent_id) : ob = TaxonConcept.find_by_id(comment.parent_id) 

			is_cur = ob.is_curatable_by?(cu)
      
			comment.update_attributes(:from_curator => is_cur) # true, if author of a comment is a curator
    end
  end


  def self.down
    #restore false for all comments!
    Comment.find(:all).each do |comment| 
      comment.update_attributes(:from_curator => false)
    end
  end
end
