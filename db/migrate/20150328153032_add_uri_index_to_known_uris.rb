class AddUriIndexToKnownUris < ActiveRecord::Migration
  def change
    # I cannot believe this isn't already there:  :|
    add_index :known_uris, :uri
  end
end
