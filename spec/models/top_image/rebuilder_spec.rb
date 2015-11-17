require "spec_helper"

describe DataObjectsTableOfContent do
  before(:all) do
    truncate_all_tables
    License.create_enumerated
    DataType.create_enumerated
    Visibility.create_enumerated
    Vetted.create_enumerated
  end
  
end