# This is a class used by tramea.
# This is a simple join model, really, just with a nice name...
class Section < ActiveRecord::Base
  belongs_to :article
  belongs_to :toc_item
end
