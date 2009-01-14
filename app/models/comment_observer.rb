class CommentObserver < ActiveRecord::Observer
  
  observe :comment
  
  def before_save comment
    if comment.visible_at_changed? and comment.vetted_by
      was = comment.visible_at_was
      is  = comment.visible_at

      if is == nil # unvetted
        CuratorCommentLog.create :comment => comment, :user => comment.vetted_by, :curator_activity => CuratorActivity.disapprove!
      elsif was == nil # vetted
        CuratorCommentLog.create :comment => comment, :user => comment.vetted_by, :curator_activity => CuratorActivity.approve!
      end
    end
  end
  
end
