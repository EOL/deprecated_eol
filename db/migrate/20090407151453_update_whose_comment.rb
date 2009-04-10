class UpdateWhoseComment < ActiveRecord::Migration
  
  def self.up
    #for old comments marks from_curator as true if author of a comment can curate a object of commenting
    Comment.find(:all).each do |comment|
			comment_user = comment.user
      # JRice changed this to use comment.user and comment.parent, instead of User.find() and the like.
      # I was getting some errors in the test database, whose state is not... err... stable.
      if comment.user && comment.parent
        this_is_curatable = comment.parent.is_curatable_by?(comment.user)
        comment.update_attributes(:from_curator => this_is_curatable) # true, if author of a comment is a curator
      end
    end
  end


  def self.down
    #restore false for all comments!
    Comment.find(:all).each do |comment| 
      comment.update_attributes(:from_curator => false)
    end
  end
end
