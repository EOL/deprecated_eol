# 
# EOL API (prototype)
#
# this is a simple client API example, using ActiveResource
#
# running this assumes that you have eol running on 
# http://localhost:3000
#
require 'rubygems'
require 'activeresource'

module EOL
  module API

    class DataObject < ActiveResource::Base

      def url
        thumb_or_object
      end

      def self.images_for_species species_or_id
        id = ( species_or_id.is_a? Fixnum ) ? species_or_id : species_or_id.id
        find :all, :from => "/v1/species/#{ id }/images"
      end

      def self.videos_for_species species_or_id
        id = ( species_or_id.is_a? Fixnum ) ? species_or_id : species_or_id.id
        find :all, :from => "/v1/species/#{ id }/videos"
      end

    end

    class Species < ActiveResource::Base

      def images
        DataObject.images_for_species self
      end

      def videos
        DataObject.videos_for_species self
      end
      
      # Examples:
      #
      # Species.search 'tiger'         # get all search results for 'tiger' (using default number of results)
      # Species.search 'tiger', 5      # only get 5 search results for 'tiger'
      # Species.search 'tiger', 1000   # try getting 1000 seach results for 'tiger' ... 
      #                                # the server side should put a limit on the number of results
      # Species.search 'tiger', 5, 2   # get page 2 of search results, assuming 5 results per page
      #
      # TODO the server side doesn't currently support pagination of search results
      #
      def self.search query, number_of_results = 10, page_of_results = 1
        find :all, :from => '/v1/species/search', :params => { :q => query.to_s, 
          :per_page => number_of_results, :page => page_of_results }
      end
      
      # Examples:
      #
      # Species.all         # get all species (using default number of results)
      # Species.all 5       # only get 5
      # Species.all 1000    # try getting 1000 ... the server side should put a limit on the number of results
      # Speciesa.all 5, 2   # get page 2 of species results, assuming 5 results per page
      #
      def self.all number_of_results = 10, page_of_results = 1
        find :all, :params => { :per_page => number_of_results, :page => page_of_results }
      end

      # returns 1 random Species
      def self.random
        find :one, :from => '/v1/species/random'
      end

    end

  end
end

ActiveResource::Base.site = 'http://localhost:3000/v1/'
