module Wapi
  module V1
    class CollectionsController < ApplicationController
      respond_to :json
      before_filter :restrict_access #, except: [:index, :show]
      before_filter :find_collection, only: [:show, :update, :destroy]

      def index
        # TODO: pagination! This would be HUGE.
        respond_with Collection.where(published: true).all
      end

      def show
        respond_with @collection
      end

      def create
        @collection = Collection.create(params[:collection])
        if @collection.save
          @collection.users = [@user]
        end
        respond_with @collection
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
      def restrict_access
        authenticate_or_request_with_http_token do |token, options|
          @user = User.find_by_api_key(params[:access_token])
        end
      end
    end
  end
end
