class CreateSpecialLists < ActiveRecord::Migration
  def self.up
    create_table 'special_lists' do |t|
      t.string :sym, :limit => '32'
      t.string :name, :limit => '32'
    end
    SpecialList.create_all
  end

  def self.down
    drop_table 'special_lists'
  end
end
