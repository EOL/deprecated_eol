class AddDataPointUriPredicateToResourceContributions < ActiveRecord::Migration
  def change
    add_column :resource_contributions, :predicate, :string
  end
end
