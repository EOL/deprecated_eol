class AddRankedCanonicalFormToNames < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE names ADD `ranked_canonical_form_id` int unsigned NULL AFTER `canonical_form_id`')
  end

  def self.down
    remove_column :names, :ranked_canonical_form_id
  end
end
