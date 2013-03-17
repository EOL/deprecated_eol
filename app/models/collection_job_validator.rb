# See http://guides.rubyonrails.org/active_record_validations_callbacks.html#custom-validators
class CollectionJobValidator < class MyValidator < ActiveModel::Validator

  def validate(job)
    unless command == 'copy' || job.user.can_edit_collection?(job.collection)
      job.errors[:base] << I18n.t(:collection_job_error_user_cannot_access_source)
    end
    unless job.command == 'remove'
      job.collections.each do |target_collection|
        if job.user.can_edit_collection?(target_collection)
          job.errors[:base] << I18n.t(:collection_job_error_user_cannot_access_target)
        end
      end
    end
  end

end
