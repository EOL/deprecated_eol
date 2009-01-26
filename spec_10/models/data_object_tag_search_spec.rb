require File.dirname(__FILE__) + '/../spec_helper'

describe DataObject, 'search by tag' do

  fixtures :roles

  before do
    @cool_object = DataObject.create_valid
    @bob = User.create_valid
  end

  it 'should return all data objects tagged with given tag' do
    DataObject.search_by_tag( :color, :blue ).should be_empty
    @cool_object.tag :color, :blue
    DataObject.search_by_tag( :color, :blue ).should include(@cool_object)
  end
  
  it 'should return all data objects tagged with given a DataObjectTag' do
    DataObject.search_by_tag( :color, :blue ).should be_empty
    @cool_object.tag :color, :blue
    DataObject.search_by_tag( DataObjectTag[:color, :blue] ).should include(@cool_object)
  end

  it 'should return all data objects tagged with given tags' do
    DataObject.search_by_tags([ [:color,:blue], [:color,:red] ]).should be_empty
    DataObject.search_by_tags([ [:color, :blue], [:color, :red] ], :boolean => :or ).should be_empty
    @cool_object.tag :color, :blue
    DataObject.search_by_tags([ [:color, :blue], [:color, :red] ]).should be_empty
    DataObject.search_by_tags([ [:color, :blue], [:color, :red] ], :boolean => :or ).should include(@cool_object)
    @cool_object.tag :color, :red
    DataObject.search_by_tags([ [:color, :blue], [:color, :red] ]).should include(@cool_object)
    DataObject.search_by_tags({ :color => :blue, :color => :red }, :boolean => :or ).should include(@cool_object)
  end

  it 'should return all data objects tagged with given an array of DataObjectTag instances' do
    DataObject.search_by_tags([ DataObjectTag[:color, :blue], DataObjectTag[:color, :red] ]).should be_empty
    DataObject.search_by_tags([ DataObjectTag[:color, :blue], DataObjectTag[:color, :red] ], :boolean => :or ).should be_empty
    
    @cool_object.tag :color, :blue
    DataObject.search_by_tags([ DataObjectTag[:color, :blue], DataObjectTag[:color, :red] ]).should be_empty
    DataObject.search_by_tags([ DataObjectTag[:color, :blue], DataObjectTag[:color, :red] ], :boolean => :or ).should include(@cool_object)

    @cool_object.tag :color, :red
    DataObject.search_by_tags([ DataObjectTag[:color, :blue], DataObjectTag[:color, :red] ]).should include(@cool_object)
    DataObject.search_by_tags([ DataObjectTag[:color, :blue], DataObjectTag[:color, :red] ], :boolean => :or ).should include(@cool_object)
  end

  it 'should return data objects sorted with the objects MOST tagged with the given tag at the top'

=begin
# snippet of HierarchyEntries (from fixtures) for reference

  [16097869] Animals [1 -> 126]
    [99901] common porro [2 -> 3]
    [99902] Rudolph's est [4 -> 5]
    [99903] giant excepturi [6 -> 7]
    [888001] Karenteen seabream [124 -> 125]
  [16098238] Plants [127 -> 128]
  [16098245] Bacteria [129 -> 130]
  [16101659] Chromista [131 -> 146]
    [16101973] <i>Sagenista</i> [132 -> 145]
      [16101974] Bicosoecids [133 -> 144]
        [16101975] <i>Bicosoecales</i> [134 -> 143]
          [16101978] <i>Cafeteriaceae</i> [135 -> 142]
            [16109089] <i>Cafeteria</i> [136 -> 139]
              [16222828] <i>Cafeteria roenbergensis</i> [137 -> 138]
            [16222829] <i>Spicy Food</i> [140 -> 141]
  [16101981] Fungi [147 -> 148]
  [16103012] Protozoa [149 -> 150]
  [16103368] Viruses [151 -> 152]
  [16106613] Archaea [153 -> 154]

=end
  describe 'filtered by clade' do

    fixtures :roles

    before do
      # delete all TopImage associations so they don't interfere with our associations
      TopImage.delete_all
    end

    # create some data objects in different clades & tag the objects
    def create_tagged_dataobject_in_clade clade, tag_key, tag_value, object = nil
      object = DataObject.first if object.nil?
      begin
      TopImage.create! :hierarchy_entry_id => clade, :data_object_id => object.id, :view_order => 1
      rescue
      end
      object.tag tag_key, tag_value
      object
    end

    # this isn't actually necessary ... i was thinkin a DataObject should know if it's .in_clade?(clade)
    it "should know if it's in a certain clade" # did Preston add something like this for the Curation?

    it 'should find an object in a given clade' do
      object = create_tagged_dataobject_in_clade 16101973, :color, :blue
      DataObject.search_by_tag( :color, :blue ).should include(object)
      DataObject.search_by_tag( :color, :blue, :clade => 16101973 ).should include(object)

      DataObject.search_by_tag( :color, :blue, :clade => 16097869 ).should_not include(object)
      DataObject.search_by_tag( :color, :blue, :clade => 99902    ).should_not include(object)
      DataObject.search_by_tag( :color, :blue, :clade => 16103012 ).should_not include(object)
    end

    it 'should find all objects in a clade (searching higher up)' do
      object = create_tagged_dataobject_in_clade 16101973, :color, :blue
      DataObject.search_by_tag( :color, :blue, :clade => 16101659 ).should include(object)
    end

    it 'should find objects given multiple clades' do
      object = create_tagged_dataobject_in_clade 16101973, :color, :blue
      object = create_tagged_dataobject_in_clade 99901, :color, :blue
      
      DataObject.search_by_tag( :color, :blue, :clade => [16101973,123] ).should include(object)
      DataObject.search_by_tag( :color, :blue, :clade => [123,16101973] ).should include(object)
      DataObject.search_by_tag( :color, :blue, :clade => [123,4568] ).should_not include(object)
      DataObject.search_by_tag( :color, :blue, :clade => [99901,123456] ).should include(object)
      DataObject.search_by_tag( :color, :blue, :clade => [99901,16101973] ).should include(object)
    end

    it 'should find objects given multiple tags and a clade' do
      object = create_tagged_dataobject_in_clade 16101973, :color, :blue
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => 99901    ).should_not include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => 16101973 ).should_not include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => 16101659 ).should_not include(object)

      object = create_tagged_dataobject_in_clade 16101973, :color, :red
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => 99901    ).should_not include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => 16101973 ).should include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => 16101659 ).should include(object)
    end

    it 'should find objects given multiple tags and clades' do
      object = create_tagged_dataobject_in_clade 16101973, :color, :blue
      object = create_tagged_dataobject_in_clade 99901, :color, :blue
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [99901, 123]      ).should_not include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [123, 16101973]   ).should_not include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [16101659, 123]   ).should_not include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [99901, 16101659] ).should_not include(object)

      object = create_tagged_dataobject_in_clade 16101973, :color, :red
      object = create_tagged_dataobject_in_clade 99901, :color, :red
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [99901, 123]      ).should include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [123, 16101973]   ).should include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [16101659, 123]   ).should include(object)
      DataObject.search_by_tags([ [:color,:blue], [:color, :red] ], :clade => [99901, 16101659] ).should include(object)
    end

  end

end
