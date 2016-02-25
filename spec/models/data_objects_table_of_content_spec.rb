require "spec_helper"

describe DataObjectsTableOfContent do
 
   before(:all) do
    truncate_all_tables
    License.create_enumerated
    DataType.create_enumerated
    Visibility.create_enumerated
    Vetted.create_enumerated
    @toc_1_id = 1
    @toc_2_id = 2
    info_item_1 = InfoItem.gen(toc_id: @toc_1_id)
    info_item_2 = InfoItem.gen(toc_id: @toc_2_id)
    
    @data_objects = []
    for i in 0..5
      @data_objects[i] = DataObject.gen
    end
    
    DataObjectsInfoItem.gen(data_object_id: @data_objects[0].id, info_item_id: info_item_1.id)
    DataObjectsInfoItem.gen(data_object_id: @data_objects[1].id, info_item_id: info_item_2.id)
    DataObjectsInfoItem.gen(data_object_id: @data_objects[4].id, info_item_id: info_item_1.id)
    DataObjectsInfoItem.gen(data_object_id: @data_objects[5].id, info_item_id: info_item_2.id)    
    DataObjectsTableOfContent.gen(data_object_id: @data_objects[0].id, toc_id: @toc_1_id)
    DataObjectsTableOfContent.gen(data_object_id: @data_objects[1].id, toc_id: @toc_2_id)
    DataObjectsTableOfContent.gen(data_object_id: @data_objects[2].id, toc_id: @toc_1_id)
    DataObjectsTableOfContent.gen(data_object_id: @data_objects[3].id, toc_id: @toc_2_id)
  end
  
  it 'should insert all DataObjectsTableOfContent' do
    ids = @data_objects.map(&:id)
    DataObjectsTableOfContent.rebuild_by_ids(ids)
    expect(DataObjectsTableOfContent.count).to equal(6)
    for i in 0..5
      dotoc = DataObjectsTableOfContent.find_by_data_object_id(@data_objects[i])
      expect(dotoc).not_to be_nil
      if [0,2,4].include?(i)
        expect(dotoc.toc_id).to equal(@toc_1_id) 
      else
        expect(dotoc.toc_id).to equal(@toc_2_id)
      end       
    end
  end
  
end