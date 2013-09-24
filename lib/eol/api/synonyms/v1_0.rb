module EOL
  module Api
    module Synonyms
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:returns_all_metadata_about_a_particular_collection) }
        DESCRIPTION = Proc.new { I18n.t(:api_docs_collections_description) }
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true,
              :test_value => (Collection.where(:name => 'EOL Group on Flickr').first || Collection.last).id ),
            EOL::Api::DocumentationParameter.new(
              :name => 'page',
              :type => Integer,
              :default => 1 ),
            EOL::Api::DocumentationParameter.new(
              :name => 'per_page',
              :type => Integer,
              :default => 50 ),
            EOL::Api::DocumentationParameter.new(
              :name => 'filter',
              :type => String,
              :values => [ 'articles', 'collections', 'communities', 'images', 'sounds', 'taxa', 'users', 'video' ] ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sort_by',
              :type => String,
              :values => SortStyle.all.map{ |ss| ss.name.downcase.gsub(' ', '_') rescue nil }.compact,
              :default => SortStyle.newest.name.downcase.gsub(' ', '_') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sort_field',
              :type => String,
              :notes => I18n.t('collection_api_sort_field_notes') )
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          begin
            synonym = Synonym.find(params[:id])
          rescue
            raise ActiveRecord::RecordNotFound.new("Unknown synonym id \"#{params[:id]}\"")
          end
          prepare_hash(synonym, params)
        end

        def self.prepare_hash(synonym, params={})
          { 'synonym' => synonym }
        end
      end
    end
  end
end
