class AddDataFieldsToEolStatistics < ActiveRecord::Migration
  def change
    add_column :eol_statistics, :total_triples, 'integer unsigned'
    add_column :eol_statistics, :total_occurrences, 'integer unsigned'
    add_column :eol_statistics, :total_measurements, 'integer unsigned'
    add_column :eol_statistics, :total_associations, 'integer unsigned'
    add_column :eol_statistics, :total_measurement_types, 'integer unsigned'
    add_column :eol_statistics, :total_association_types, 'integer unsigned'
    add_column :eol_statistics, :total_taxa_with_data, 'integer unsigned'
  end
end
