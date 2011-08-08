class UpdateWhoseComment < ActiveRecord::Migration

  def self.up
    #for old comments marks from_curator as true if author of a comment can curate a object of commenting
    begin
      Comment.find(:all).each do |comment|
        comment_user = comment.user
        if comment.user && comment.parent
          was_curator = comment.user.is_curator?
          comment.update_attributes(:from_curator => was_curator)
        end
      end
    rescue
      # TODO: I'm getting an 'uninitialized constant EOL::ActivityLogItem' error
    end
  end


  def self.down
    #restore false for all comments!
    Comment.find(:all).each do |comment|
      comment.update_attributes(:from_curator => false)
    end
  end
end
