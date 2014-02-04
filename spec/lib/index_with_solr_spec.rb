require "spec_helper"

describe 'Index With Solr' do

  before(:all) do
    Language.create_english
    @solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
    @original_index_config = $INDEX_RECORDS_IN_SOLR_ON_SAVE
    $INDEX_RECORDS_IN_SOLR_ON_SAVE = true
  end

  after(:all) do
    # remove callbacks
    class GlossaryTerm < ActiveRecord::Base
      remove_index_with_solr
    end
    $INDEX_RECORDS_IN_SOLR_ON_SAVE = @original_index_config
  end

  it 'should define new methods and set callback functions' do
    class GlossaryTerm < ActiveRecord::Base
      remove_index_with_solr
    end
    gt = GlossaryTerm.create(term: 'trust', definition: 'Firm reliance on the integrity, ability, or character of a person or thing')
    gt.respond_to?('add_to_index').should == false
    gt.respond_to?('remove_from_index').should == false
    gt.should_not_receive(:add_to_index)
    gt.save
    gt.should_not_receive(:remove_from_index)
    gt.destroy

    # add callbacks and make sure they exist
    class GlossaryTerm < ActiveRecord::Base
      index_with_solr keywords: [:term, :definition]
    end
    gt = GlossaryTerm.create(term: 'honor', definition: 'integrity')
    gt.respond_to?('add_to_index').should == true
    gt.respond_to?('remove_from_index').should == true
    gt.should_receive(:add_to_index)
    gt.save
    gt.should_receive(:remove_from_index)
    gt.destroy

    # remove callbacks and make sure they are gone again
    class GlossaryTerm < ActiveRecord::Base
      remove_index_with_solr
    end
    gt = GlossaryTerm.create(term: 'bubble', definition: 'sphere')
    gt.respond_to?('add_to_index').should == false
    gt.respond_to?('remove_from_index').should == false
    gt.should_not_receive(:add_to_index)
    gt.save
    gt.should_not_receive(:remove_from_index)
    gt.destroy
  end

  it 'should index the object on creation' do
    # add callbacks - they will exist for the remainder of the tests
    class GlossaryTerm < ActiveRecord::Base
      index_with_solr keywords: [:term, :definition]
    end

    @solr_connection.delete_all_documents
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm')['response']['docs']
    docs.size.should == 0

    term = 'funny'
    definition = 'my life'
    gt = GlossaryTerm.create(term: term, definition: definition)
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm')['response']['docs']
    docs.size.should == 2

    term_result = docs.detect{ |h| h['keyword_type'] == 'term' }
    term_result['keyword'].should == [term]
    term_result['resource_id'].should == gt.id
    term_result['language'].should == Language.english.iso_code

    definition_result = docs.detect{ |h| h['keyword_type'] == 'definition' }
    definition_result['keyword'].should == [definition]
    definition_result['resource_id'].should == gt.id
    definition_result['language'].should == Language.english.iso_code
  end

  it 'should update the index records on update' do
    class GlossaryTerm < ActiveRecord::Base
      index_with_solr keywords: [:term, :definition]
    end
    
    @solr_connection.delete_all_documents
    term = 'trusted'
    definition = 'my mom'
    gt = GlossaryTerm.create(term: term, definition: definition)
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm AND keyword:trusted')['response']['docs']
    docs.size.should == 1

    gt.term = 'dishonor'
    gt.save
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm AND keyword:trusted')['response']['docs']
    docs.size.should == 0

    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm AND keyword:dishonor')['response']['docs']
    docs.size.should == 1
  end

  it 'should remove index records on destroy' do
    # add callbacks - they will exist for the remainder of the tests
    class GlossaryTerm < ActiveRecord::Base
      index_with_solr keywords: [:term, :definition]
    end
    
    @solr_connection.delete_all_documents
    term = 'gravity'
    definition = 'downward pull'
    gt = GlossaryTerm.create(term: term, definition: definition)
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm AND keyword:gravity')['response']['docs']
    docs.size.should == 1

    gt.destroy
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm AND keyword:gravity')['response']['docs']
    docs.size.should == 0
  end

  it 'should index based on methods as well as fields' do
    exception = false
    class GlossaryTerm < ActiveRecord::Base
      index_with_solr keywords: [:term, :definition, :some_new_method]

      def some_new_method
        term + " :: " + definition
      end
    end

    term = 'missile'
    definition = 'rocket'
    gt = GlossaryTerm.create(term: term, definition: definition)
    docs = @solr_connection.query_lucene('resource_type:GlossaryTerm AND keyword:missile')['response']['docs']
    docs.size.should == 2

    new_method_result = docs.detect{ |h| h['keyword_type'] == 'some_new_method' }
    new_method_result['keyword'].should == [term + " :: " + definition]
    new_method_result['resource_id'].should == gt.id
    new_method_result['language'].should == Language.english.iso_code
    
    gt.destroy
  end

  it 'should throw an error if the field to index on doesnt exist' do
    exception = false
    class GlossaryTerm < ActiveRecord::Base
      index_with_solr keywords: [:term, :definition, :some_nonsense]
    end

    begin
      gt = GlossaryTerm.create(term: 'green', definition: 'color')
    rescue Exception => e
      exception = e
    end
    exception.should_not == false
    exception.message.should == "NoMethodError: undefined method `some_nonsense' for GlossaryTerm"
  end
end
