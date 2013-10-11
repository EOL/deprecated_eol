class AddPositionToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :position, :integer
    # Initial order doesn't matter much (but we want one), so let's just go by URL alpha:
    i = 0
    KnownUri.all.sort_by(&:uri).each { |uri| uri.update_attribute(:position, i += 1) }
  end
end
