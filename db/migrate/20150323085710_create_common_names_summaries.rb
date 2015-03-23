class CreateCommonNamesSummaries < ActiveRecord::Migration
  def change
    create_table :common_names_summaries, id: false do |t|
      t.integer :common_name_id
      t.integer :summary_id
      t.timestamps
    end
    # NOTE: We're never going to look these up by common_name.
    add_index :common_names_summaries, :summary_id
    add_index :common_names_summaries,
      [:common_name_id, :summary_id],
      unique: true,
      name: "pk"
  end
end
