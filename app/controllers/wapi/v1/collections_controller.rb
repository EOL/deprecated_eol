module Wapi
  module V1
    class CollectionsController < ApplicationController
      respond_to :json
      before_filter :restrict_access, except: [:index, :show]
      before_filter :find_collection, only: [:update, :destroy]

      def index
        # TODO: pagination! This would be HUGE.
        respond_with Collection.where(published: true).all
      end

      def show
        respond_with Collection.where(id: params[:id]).
          includes(:collection_items).first, items: true
      end

      def create
        # Rails wants "collection_items_attributes", which it would use if
        # generating the form itself, but that's lame in the context of 3rd
        # party input JSON, so I update it here:
        params[:collection][:collection_items_attributes] =
          params[:collection].delete(:collection_items) if
          params[:collection] && params[:collection][:collection_items]
        @collection = Collection.create(params[:collection])
        if @collection.save
          @collection.users = [@user]
          respond_with @collection
        else
          respond_with(@collection, status: :unprocessable_entity) do |format|
            format.json { render json: { errors: @collection.errors.full_messages }.to_json }
          end
        end
      end

      def update
        head :unauthorized unless @user.can_update?(@collection)
        respond_with @collection.update(params[:collection])
      end

      def destroy
        head :unauthorized unless @user.can_delete?(@collection)
        respond_with @collection.destroy
      end

      private

      def find_collection
        @collection = Collection.find(params[:id])
      end

      # -H 'Authorization: Token token="ABCDEF12345"'
      # See also the request specs.
      def restrict_access
        authenticate_or_request_with_http_token do |token, options|
          @user = User.find_by_api_key(token)
        end
      end
    end
  end
end
