
describe 'data_objects/edit' do
  
  let(:data_object) { stub_model(DataObject) }

  before(:each) do      
    @taxon_concept = build_stubbed(TaxonConcept)
    @user = build_stubbed(User)
    @data_object = build_stubbed(DataObject, language_id: 1, license_id: 1)
    @data_object.stub(:is_text?) { true } 
    @data_object.stub(:errors) { [] }  
    @data_object.stub(:is_link?) { true }  
    @toc_items = TocItem.selectable_toc                  
    @languages = [build_stubbed(Language, source_form: 'English')]              
    @licenses = [build_stubbed(License, title: 'public domain')]   
  end

  describe 'GET edit' do 
    it "should have Reference order notification" do      
      form_for data_object, builder: ApplicationHelper::EolFormBuilder do |dato_form|        
        allow(view).to receive(:f).and_return(dato_form)              
        render :partial => 'data_objects/text_fieldset', :id => @data_object.id, :f => dato_form
        expect(rendered).to have_content(I18n.t('helpers.label.data_object.refs_order'))     
      end 
    end
  end
end
