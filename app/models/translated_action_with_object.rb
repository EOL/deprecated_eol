class TranslatedActionWithObject < ActiveRecord::Base
  belongs_to :action_with_object
  belongs_to :language
end
