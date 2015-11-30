require "spec_helper"

describe DataObjectsTableOfContent do
  before(:all) do
    truncate_all_tables
    License.create_enumerated
    DataType.create_enumerated
    Visibility.create_enumerated
    Vetted.create_enumerated
  end

  # TODO: test sort on vetted view order and rating (don't worry about data
  # object id sort), on a leaf node and its ancestors, for both TopImage and
  # TopUnpublishedImage/
end
