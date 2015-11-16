module Wapi
  module V1
    class CollectionsController < ApplicationController
      respond_to :json
      before_filter :restrict_access, except: [:index, :show]
      before_filter :find_collection, only: [:update, :destroy]
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
              params[:collection][:collection_items_attributes] =
                 params[:collection].delete(:collection_items)
              @collection = Collection.create!(params[:collection])
              CollectionItem.counter_culture_fix_counts
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
         respond_with @collection.reload , status: :ok unless errors
      end

      def update
        if @collection.blank?
          respond_with do |format|
            format.json { render json: I18n.t(:collection_not_existing, collection:params[:id]).to_json, status: :not_found }
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
                 add_collection_items
               end
            else
              raise Exception.new I18n.t :collection_update_empty_parameters_failure
            end
          rescue Exception => e
            respond_with do |format|
              format.json { render json: (I18n.t(:collection_update_failure, collection: @collection.id) + e.to_s).to_json, status: :unprocessable_entity }
            end
            errors = true
            raise ActiveRecord::Rollback
          end
        end
         respond_with @collection.reload  unless errors
      end

      def destroy
        if @collection.blank?
           respond_with do |format|
          format.json { render json: I18n.t(:collection_not_existing, collection:params[:id]).to_json, status: :not_found }
            end
          return
        end
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        @collection.collection_items.destroy_all
        @collection.destroy
        respond_with do |format|
          format.json { render json: I18n.t(:collection_removed, collection: @collection.id).to_json, status: :ok }
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

    end
  end
end
