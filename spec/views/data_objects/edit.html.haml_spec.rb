#require ckeditor_fix        #- add this line
#require "ckeditor/init"

describe 'data_objects/edit' do
  
  let(:data_object) { stub_model(DataObject) }

  before(:each) do      
    @taxon_concept = double(TaxonConcept)
    @taxon_concept.stub(:id) { 1 }
    @user = double(User)
    @user.stub(:id) { 1 }    
    @data_object = double(DataObject)
    @data_object.stub(:id) { 1 }
    @data_object.stub(:is_text?) { true }   
    @data_object.stub(:is_link?) { true } 
    @data_object.stub(:errors) { [] }
    @data_object.stub(:language_id) { 1 }
    @data_object.stub(:license_id) { 1 }    
    @toc_items = TocItem.selectable_toc          
    lang1 = double(Language)
    lang1.stub(:source_form) { 'English' }
    lang1.stub(:id) { 1 }    
    @languages = [lang1]         
    lic1 = double(License)
    lic1.stub(:title) { 'public domain' } 
    lic1.stub(:id) { 1 } 
    @licenses = [lic1]   
  end

  describe 'GET edit' do 
    it "should have Reference order notification" do      
      form_for data_object, :builder => ApplicationHelper::EolFormBuilder do |f|        
        allow(view).to receive(:f).and_return(f)              
        render :partial => 'data_objects/text_fieldset', :id => @data_object.id, :f => f
        expect(rendered).to have_content(I18n.t('helpers.label.data_object.refs_order'))     
      end 
    end
  end
end
