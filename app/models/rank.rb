class Rank < SpeciesSchemaModel
  has_many :hierarchy_entries
  has_many :group_members, :class_name => 'Rank', :primary_key => 'rank_group_id', :foreign_key => 'rank_group_id', :conditions => 'rank_group_id!=0'
  
  def self.kingdom
    cached_find(:label, 'kingdom')
  end
  
  def self.phylum
    cached_find(:label, 'phylum')
  end
  
  def self.class
    cached_find(:label, 'class')
  end
  
  def self.order
    cached_find(:label, 'order')
  end
  
  def self.family
    cached_find(:label, 'family')
  end
  
  def self.genus
    cached_find(:label, 'genus')
  end
  
  def self.species
    cached_find(:label, 'species')
  end
  
  def self.subspecies
    cached_find(:label, 'subspecies')
  end
  
  
  
  
  
  
  def self.italicized_ids
    self.italicized_ids_sub
  end

  def self.italicized_ids_sub
    cached('italicized') do 
      @@ids = Rank.find_by_sql(%q{SELECT * FROM ranks WHERE label IN (
               '?var',          'binomial',      'biovar',
               'Espéce',        'especie',       '',
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
  
  def self.tcs_codes
    #TODO - we could add a code column to the table, but these codes are specific to the Taxon Concept Schema
    cached('codes') do
      { 'kingdom'     => 'reg',
        'phylum'      => 'phyl_div',
        'class'       => 'cl',
        'subclass'    => 'subcl',
        'order'       => 'ord',
        'suborder'    => 'subord',
        'superfamily' => 'superfam',
        'family'      => 'fam',
        'subfamily'   => 'subfam',
        'genus'       => 'gen',
        'species'     => 'sp',
        'sp'          => 'sp' }
    end
  end
  
  def tcs_code
    if c = Rank.tcs_codes.include?(label.downcase)
      return Rank.tcs_codes.fetch(label.downcase)
    end
    return nil
  end

end
