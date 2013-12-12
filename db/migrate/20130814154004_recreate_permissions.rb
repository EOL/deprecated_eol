# NOTE - once our deploys have a rake task to run all of these create_defaults, we should delete this migration.
class RecreatePermissions < ActiveRecord::Migration
  def up
    Permission.create_enumerated
    EolConfig.create_defaults
  end

  def down
    # Nothing to do.
  end
end
