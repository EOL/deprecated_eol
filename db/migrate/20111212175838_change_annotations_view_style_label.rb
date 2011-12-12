class ChangeAnnotationsViewStyleLabel < ActiveRecord::Migration
  def self.up
    execute "UPDATE translated_view_styles SET name='Annotated' WHERE name='Annotations'"
  end

  def self.down
    execute "UPDATE translated_view_styles SET name='Annotations' WHERE name='Annotated'"
  end
end
