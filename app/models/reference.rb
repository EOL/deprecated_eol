# This is a model used by Tramea. It's essentially "refs", but easier.
class Reference < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
end
