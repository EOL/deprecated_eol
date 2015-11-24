module Wapi
  module V1
    class CollectionsController < ApplicationController
      respond_to :json
       before_filter :restrict_access, except: [:index, :show]
      before_filter :find_collection, only: [:update, :destroy]
      after_filter :reindex_collection, only: [:create, :update]
      DEFAULT_ITEMS_NUMBER_PER_PAGE = 30

      def index
        respond_with Collection.where(published: true).paginate(page: params[:page] ||= 1, per_page: params[:per_page] ||= DEFAULT_ITEMS_NUMBER_PER_PAGE)
      end

      def show
        respond_with Collection.where(id: params[:id]).
          includes(:collection_items).first, items: true
      end

      def create
        errors = nil
        ActiveRecord::Base.transaction do
          begin
            unless params[:collection].blank?
              params[:collection][:users] = [@user]
              @collection = Collection.create!(params[:collection].except(:collection_items))
              grouped_collection_items =  params[:collection][:collection_items].
              group_by{ |i| i["collected_item_type"]} rescue []
              valid_collected_item_type?(grouped_collection_items.keys)
              grouped_collection_items.each do |key, group |
                add_grouped_collection_items(key, group)
              end
            else
              raise Exception.new I18n.t :collection_create_empty_parameters_failure
            end
          rescue Exception => e
            respond_with(@collection, status: :unprocessable_entity) do |format|
              format.json { render json: (I18n.t(:collection_create_failure) + e.to_s).to_json }
            end
            errors = true
            raise ActiveRecord::Rollback
        end
      end
       unless errors
         @collection.update_attributes(collection_items_count: @collection.items.count)
         respond_with( @collection, status: :ok) 
       end
      end

      def update
        if @collection.blank?
          respond_with do |format|
            format.json { render json: I18n.t(:collection_not_existing,
               collection:params[:id]).to_json, status: :not_found }
          end
          return
        end
        errors = nil
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        ActiveRecord::Base.transaction do
          begin
            unless params[:collection].blank?
               @collection.update_attributes(params[:collection].except(:collection_items))
              if params[:collection][:collection_items]
                 @collection.items.destroy_all
                    grouped_collection_items =  params[:collection][:collection_items].
                  group_by{ |i| i["collected_item_type"]} rescue []
                  valid_collected_item_type?(grouped_collection_items.keys)
                  grouped_collection_items.each do |key, group |
                    add_grouped_collection_items(key, group)
                  end
              end
            else
              raise Exception.new I18n.t :collection_update_empty_parameters_failure
            end
          rescue Exception => e
            respond_with do |format|
              format.json { render json: (I18n.t(:collection_update_failure, 
                collection: @collection.id) + e.to_s).to_json, status: :unprocessable_entity }
            end
            errors = true
            raise ActiveRecord::Rollback
          end
        end
        unless errors
          @collection.update_attributes(collection_items_count: @collection.items.count)
         respond_with do |format|
          format.json { render json: @collection.to_json, status: :ok }
        end
       end
      end

      def destroy
        if @collection.blank?
           respond_with do |format|
          format.json { render json: I18n.t(:collection_not_existing,
             collection:params[:id]).to_json, status: :not_found }
            end
          return
        end
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        @collection.collection_items.destroy_all
        @collection.destroy
        respond_with do |format|
          format.json { render json: I18n.t(:collection_removed, 
            collection: @collection.id).to_json, status: :ok }
        end
      end

      private

      def find_collection
        @collection = Collection.find_by_id(params[:id])
      end

      # -H 'Authorization: Token token="ABCDEF12345"'
      # See also the request specs.
      def restrict_access
        authenticate_or_request_with_http_token do |token, options|
          @user = User.find_by_api_key(token)
        end
      end

      def add_collection_items
        params[:collection][:collection_items].each do |hash|
          item = CollectionItem.create!(hash.merge(added_by_user_id: @user.id, collection_id: @collection.id))
        end
      end
      
      def add_grouped_collection_items(key, group)
        inserts = []
        duplicate_entries?(key, group)
        group.each do |item|
           missing_values?(item)
          name = item[:name].blank? ? "NULL" : "'#{item[:name]}'" 
           type = item[:collected_item_type].blank? ? "NULL" : "'#{item[:collected_item_type]}'"
           annotation = item[:annotation].blank? ? "NULL" : "'#{item[:annotation]}'"
           sort_field = item[:sort_field].blank? ? "NULL" : "'#{item[:sort_field]}'"

           inserts.push "(#{name} , #{type}" \
           " , #{item[:collected_item_id]}, #{@collection.id}" \
           " , #{annotation} , #{@user.id}, #{sort_field})"
        end
        sql = "INSERT INTO collection_items (`name`, `collected_item_type`, `collected_item_id`,"\
        " `collection_id`, `annotation`, `added_by_user_id`, `sort_field`) VALUES #{inserts.join(", ")}"
        ActiveRecord::Base.connection.execute sql
      end
    
      def valid_collected_item_type?(types)
        invalid = types.delete_if{|t| ['Collection','Community','DataObject','TaxonConcept', 'User'].include?(t)}
         raise EOL::Exceptions::InvalidCollectionItemType.new(
          I18n.t(:cannot_create_collection_items_from_invalid_types,
          types: invalid.join(","))) unless invalid.blank?
      end
      
      def missing_values?(item)
        i = CollectionItem.new item
         raise EOL::Exceptions::CollectionItemMissingValues.new( I18n.t :collection_items_missing_values,
           item: i.attributes.to_s ) unless i.valid?
      end
  
      def duplicate_entries?(type, collection_items)
        duplicates = collection_items.group_by{|item| item[:collected_item_id] }.
        select { |k, v| v.size > 1 }.keys
         raise EOL::Exceptions::DuplicateCollectionItems.new( I18n.t(:collection_items_duplicate_ids,
        values: duplicates.join(","), type: type )) unless duplicates.blank?
      end

      def reindex_collection
        if @collection
          EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(@collection)
          @collection.update_attribute(:collection_items_count, @collection.collection_items.count)
        
        end
      end
    end
  end
end
