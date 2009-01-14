class MoveCommentsToRailsSidePartOne < ActiveRecord::Migration

  def self.up
    create_table :comments do |t|
      t.references :user
      t.integer    :parent_id,   :null => false
      t.string     :parent_type, :null => false
      t.text       :body,        :null => false
      t.datetime   :visible_at
      t.timestamps
    end

    add_index :comments, :parent_id
    # NOTE: I am ***not*** adding an index to parent_type, because it would have VERY low cardinality, which would make it slower
    # than we want it to be.  I'm not happy about this, and worry that the query is going to return an absurd number of rows every
    # time: I hope the QOpimizer will honor _id first, of course!  :)

    puts '*' * 76
    puts '** WARNING: We\'re changing the design of the comments table when we'
    puts '**          move it, so you WILL LOSE ALL COMMENTS with this migration.'
    puts '*' * 76

  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Reversing this migration would lose all comments.  Drop the table yourself.") unless
      Comment.count == 0
    drop_table :comments
  end

end
