class OverviewTraits
  attr_reader :traits, :more

  # Copied from TaxonDataExemplarPicker, which this class will replace.
  @max_rows = EolConfig.max_taxon_data_exemplars rescue 8
  @max_values_per_row = EolConfig.max_taxon_data_exemplar_values_per_row rescue 3

  def self.max_rows
    @max_rows
  end

  def self.max_values_per_row
    @max_values_per_row
  end

  # TODO: the excluded bit might move here, too. Not sure.
  def initialize(traits)
    @traits = traits.sort_by! do |trait|
      [ trait.point.included? ? 0 : 1, trait.value_name ]
    end
    @more = @traits.count > self.class.max_values_per_row
    @traits = @traits[0..self.class.max_values_per_row - 1]
  end

  def more?
    more
  end
end
