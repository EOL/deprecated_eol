#
# API-specific controller ( prototype )
#
# TODO rename?  if necessary
# 
# TODO add pagination to * actions
# 
# TODO move serialization into models? (model should know howto serialize itself)
# 
# TODO instead of always passing along vetted/published conditions, it sure would be
#      nice if we could use a named scope ... TaxonConcept.publicly_visible.find :all
#
class SpeciesController < ApplicationController

  before_filter :set_limit_and_offset

  def index
    @species = TaxonConcept.find :all, :limit => @limit, :offset => @offset,
               :conditions => ['vetted_id = ? and published = ?', Vetted.trusted.id, 1]
    respond_to do |format|
      format.html { render :text => @species.map {|s| s.attributes.inspect }.join(' | ') }
      format.xml  { render :xml  => @species.to_xml(serialization_options)  }
      format.json { render :json => @species.to_json(serialization_options) }
    end
  end

  # TODO the API for doing a search is kindof unintuitive and it doesn't even return TaxonConcepts!  fix?
  # 
  # TODO search doesn't currently support pagination?
  #
  def search
    search = Search.new( params, request, current_user, current_agent )
    results = []
    results += search.common_name_results     if search.common_name_results
    results += search.scientific_name_results if search.scientific_name_results
    results.uniq!
    ids = results.map {|result| result['id'].to_i }
    @species = TaxonConcept.find :all, :conditions => [ "id IN (?)", ids ]

    respond_to do |format|
      format.html { render :text => @species.map {|s| s.attributes.inspect }.join(' | ') }
      format.xml  { render :xml  => @species.to_xml(serialization_options)  }
      format.json { render :json => @species.to_json(serialization_options) }
    end
  end

  # returns 1 random species
  #
  # TODO implement TaxonConcept.random(number-of-results) ... why does RandomTaxon exist?
  #
  def random
    @species = TaxonConcept.find :first, :offset => ( TaxonConcept.count * rand ),
               :conditions => ['vetted_id = ? and published = ?', Vetted.trusted.id, 1]
    respond_to do |format|
      format.html { render :text => @species.attributes.inspect }
      format.xml  { render :xml  => @species.to_xml(serialization_options)  }
      format.json { render :json => @species.to_json(serialization_options) }
    end
  end

  def show
    @species = TaxonConcept.find params[:id]
    respond_to do |format|
      format.html { render :text => @species.attributes.inspect }
      format.xml  { render :xml  => @species.to_xml(serialization_options)  }
      format.json { render :json => @species.to_json(serialization_options) }
    end
  end

  protected

  def serialization_options
    {
      :methods => [ :name, :common_name, :scientific_name ],
      :only    => [ :id ]
    }
  end

  # based on whether page / per_page params were passed (or using defaults), 
  # set @limit and @offset which can then be passed into find methods
  #
  # Foo.find :limit => @limit, :offset => @offset
  #
  def set_limit_and_offset
    @limit  = ( params[:per_page] || 10 ).to_i
    page    = ( params[:page]     || 1  ).to_i
    @offset = ( page - 1 ) * @limit
  end

end
