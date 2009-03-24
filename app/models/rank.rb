class Rank < SpeciesSchemaModel
  has_many :hierarchy_entries

  def self.italicized_ids
    self.italicized_ids_sub
  end

  def self.italicized_ids_sub
    Rails.cache.fetch('ranks/italicized') do 
      @@ids = Rank.find_by_sql(%q{SELECT * FROM ranks WHERE label IN (
               '?var',          'binomial',      'biovar',
               'Espéce',        'especie',       'f',
               'f.',            'f.sp.',         'form',
               'forma',         'infra-form',    'infra-species',
               'infra-variety', 'infraspecies',  'infravariety',
               'micro-species', 'microspecies',  'nohtosubsp',
               'nopthosubsp',   'notho species', 'nothof',
               'nothosubsp',    'nothosupsp',    'nothovar',
               'nssp',          'nsubsp',        'quadrinomial',
               'sbsp',          'sebsp',         'SP',
               'sp.',           'sp.-group',     'species',
               'species forma', 'species group', 'species subgroup',
               'specio',        'ssp',           'ssp.',
               'sub-form',      'sub-forma',     'sub-species',
               'sub-variety',   'subform',       'subfsp',
               'subsp',         'subsp.',        'subspecies',
               'subspecific',   'subspsp',       'subv',
               'subvar',        'subvar.',       'subvar. [?]',
               'subvarietas',   'subvariety',    'subvarsp',
               'supsp',         'susbp',         'susbsp',
               'susp',          'trinomial',     'var',
               'var.',          'variety',       'varsp'
      )}).map(&:id)
    end
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: ranks
#
#  id            :integer(2)      not null, primary key
#  rank_group_id :integer(2)      not null
#  label         :string(50)      not null

