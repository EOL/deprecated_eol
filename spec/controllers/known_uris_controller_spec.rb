require "spec_helper"

def create_known_uri(params)
  new_instance = KnownUri.create(uri: params[:uri], uri_type_id: params[:uri_type_id],
    vetted_id: Vetted.trusted.id, visibility_id: Visibility.visible.id)
  TranslatedKnownUri.create(known_uri: new_instance, name: params[:name], language: Language.english)
  new_instance
end

def expect_measurement_types
  EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).at_least(1).times.and_return(KnownUri.measurements)
end

def expect_no_measurement_types
  EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).at_least(1).times.and_return([])
end


# TODO - this isn't a controller spec, it's a feature spec. Move it.
describe KnownUrisController do

  before(:all) do
    load_foundation_cache
    @user = User.gen
    @user.grant_permission(:see_data)
    @full = FactoryGirl.create(:curator)
    @full.grant_permission(:see_data)
    @master = FactoryGirl.create(:master_curator)
    @master.grant_permission(:see_data)
    @admin = User.gen(:admin => true)
    @admin.grant_permission(:see_data)
    # creating some allowed units for Mass
    @mass = KnownUri.gen_if_not_exists({ uri: Rails.configuration.uri_term_prefix + 'mass', name: 'Mass', uri_type_id: UriType.measurement.id })
    @length = KnownUri.gen_if_not_exists({ uri: Rails.configuration.uri_term_prefix + 'length', name: 'Length', uri_type_id: UriType.measurement.id })
    @sex = KnownUri.find_by_translated(:name, 'Sex')
    @male = KnownUri.find_by_translated(:name, 'Male')
    @female = KnownUri.find_by_translated(:name, 'Female')
    @source = KnownUri.find_by_translated(:name, 'Source')
    [ KnownUri.milligrams, KnownUri.grams, KnownUri.kilograms ].each do |unit|
      KnownUriRelationship.gen(from_known_uri: @mass, to_known_uri: unit,
        relationship_uri: KnownUriRelationship::ALLOWED_UNIT_URI)
    end
  end

  before(:each) do
    session[:user_id] = @user.id
  end

  describe 'GET index' do
    it 'should work for admins' do
      session[:user_id] = @admin.id
      expect { get :index }.not_to raise_error
    end

    it 'should work for master curators' do
      session[:user_id] = @master.id
      expect { get :index }.not_to raise_error
    end

    it 'should deny access for full curators' do
      session[:user_id] = @full.id
      expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should deny access for users with data privilege' do
      session[:user_id] = @user.id
      expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should deny access to normal or non-logged-in users' do
      session[:user_id] = User.gen.id
      expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
      session[:user_id] = nil
      expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
  end

  describe 'GET autocomplete_known_uri_search' do

    it 'should allow access to users with data privilege' do
      expect { get :autocomplete_known_uri_search }.not_to raise_error
    end

    # the method allows an empty search, but the JS will only call this method when there are at least 2 characters
    it 'should not return any KnownUris without a search term by default' do
      get :autocomplete_known_uri_search, :term => ''
      assigns[:known_uris].should == []
    end

    # the method allows an empty search, but the JS will only call this method when there are at least 2 characters
    it 'should return matching KnownUris based on search term' do
      get :autocomplete_known_uri_search, :term => 'grams'
      assigns[:known_uris].should == [ KnownUri.milligrams, KnownUri.grams, KnownUri.kilograms, KnownUri.log10_grams ]
      get :autocomplete_known_uri_search, :term => Rails.configuration.uri_obo + 'UO_0000021'
      assigns[:known_uris].should == [ KnownUri.grams ]
      get :autocomplete_known_uri_search, :term => 'milligrams'
      assigns[:known_uris].should == [ KnownUri.milligrams ]
      get :autocomplete_known_uri_search, :term => 'http://'
      assigns[:known_uris].should == KnownUri.all
    end

    it 'should return nothing when there is no match' do
      get :autocomplete_known_uri_search, :term => 'nonsense'
      assigns[:known_uris].should == [ ]
    end
  end

  describe 'GET autocomplete_known_uri_predicates' do

    it 'should allow access to users with data privilege' do
      expect { get :autocomplete_known_uri_predicates }.not_to raise_error
    end

    # the method allows an empty search, but the JS will only call this method when there are at least 2 characters
    it 'should return all measurements when there is no term' do
      expect_measurement_types
      KnownUri.measurements.length.should == 2
      get :autocomplete_known_uri_predicates, :term => ''
      assigns[:known_uris].should == KnownUri.measurements
    end

    it 'should allow searches within measurements' do
      expect_measurement_types
      debugger if KnownUri.unit_of_measure.allowed_values.length == 9 # What's the extra one and how should we clear it out?
      get :autocomplete_known_uri_predicates, :term => 'mass'
      assigns[:known_uris].should == [ @mass ]
      get :autocomplete_known_uri_predicates, :term => 'http://'
      assigns[:known_uris].should == KnownUri.measurements
    end

    it 'should only return results for valid measurements' do
      expect_no_measurement_types
      get :autocomplete_known_uri_predicates, :term => 'mass'
      assigns[:known_uris].should == [ ]
      get :autocomplete_known_uri_predicates, :term => 'http://'
      assigns[:known_uris].should == [ ]
    end

  end

  describe 'GET autocomplete_known_uri_units' do

    it 'should allow access to users with data privilege' do
      expect { get :autocomplete_known_uri_units, term: 'foo' }.not_to raise_error
    end

    it 'should return all visible units when there is no term and no predicate' do
      get :autocomplete_known_uri_units, :term => ''
      assigns[:known_uris].should == KnownUri.default_units_for_form_select
    end

    it 'should return a list of visible allowed units when given a predicate' do
      get :autocomplete_known_uri_units, :term => '', :predicate_known_uri_id => @mass.id
      assigns[:known_uris].should == [ KnownUri.milligrams, KnownUri.grams, KnownUri.kilograms ]
      KnownUri.milligrams.update_column(:visibility_id, Visibility.invisible.id)
      get :autocomplete_known_uri_units, :term => '', :predicate_known_uri_id => @mass.id
      assigns[:known_uris].should == [ KnownUri.grams, KnownUri.kilograms ]
      KnownUri.milligrams.update_column(:visibility_id, Visibility.visible.id)
    end

    it 'should allow searches within units' do
      get :autocomplete_known_uri_units, :term => 'grams'
      assigns[:known_uris].map(&:name).should ==
        [ KnownUri.milligrams, KnownUri.grams, KnownUri.kilograms, KnownUri.log10_grams ].map(&:name)
      get :autocomplete_known_uri_units, :term => Rails.configuration.uri_obo + 'UO_0000021'
      assigns[:known_uris].should == [ KnownUri.grams ]
      get :autocomplete_known_uri_units, :term => 'milligrams'
      assigns[:known_uris].should == [ KnownUri.milligrams ]
      get :autocomplete_known_uri_units, :term => 'http://'
      assigns[:known_uris].should == KnownUri.unit_of_measure.allowed_values
    end

    it 'should still allow searches given a predicate, but the predicate will be ignored' do
      # note that ALL units are getting returned even though we're providing a predicate with specified units
      get :autocomplete_known_uri_units, :term => 'http://', :predicate_known_uri_id => @mass.id
      assigns[:known_uris].should == KnownUri.unit_of_measure.allowed_values
    end
  end

  describe 'GET autocomplete_known_uri_metadata' do

    it 'should allow access to users with data privilege' do
      expect { get :autocomplete_known_uri_metadata, term: 'foo' }.not_to raise_error
    end

    it 'should return all visible metadata URIs when there is no term' do
      KnownUri.metadata.length.should == 5
      get :autocomplete_known_uri_metadata, :term => ''
      assigns[:known_uris].should == KnownUri.metadata
      KnownUri.metadata.last.update_column(:visibility_id, Visibility.invisible.id)
      get :autocomplete_known_uri_metadata, :term => ''
      assigns[:known_uris].should == KnownUri.metadata[0..-2]
      KnownUri.metadata.last.update_column(:visibility_id, Visibility.visible.id)
    end

    it 'should allow searches within metadata' do
      get :autocomplete_known_uri_metadata, :term => 'source'
      assigns[:known_uris].should == [ @source ]
      # note that ALL units are getting returned even though we're providing a predicate with specified units
      get :autocomplete_known_uri_metadata, :term => 'http://'
      assigns[:known_uris].should == KnownUri.metadata
    end

    it 'should be able to search for non-visible metadata' do
      last_term = KnownUri.metadata.last
      get :autocomplete_known_uri_metadata, :term => last_term.name
      assigns[:known_uris].should == [ last_term ]
      last_term.update_column(:visibility_id, Visibility.invisible.id)
      get :autocomplete_known_uri_metadata, :term => last_term.name
      assigns[:known_uris].should == [ last_term ]
      last_term.update_column(:visibility_id, Visibility.visible.id)
    end

    it 'should not return UnitOfMeasure if supplied predicate has specified units' do
      KnownUri.metadata.length.should == 5
      get :autocomplete_known_uri_metadata, :term => ''
      assigns[:known_uris].should include(KnownUri.unit_of_measure)
      get :autocomplete_known_uri_metadata, :term => '', :predicate_known_uri_id => @mass.id
      assigns[:known_uris].should_not include(KnownUri.unit_of_measure)
    end
  end

  describe 'GET autocomplete_known_uri_values' do

    it 'should allow access to users with data privilege' do
      expect { get :autocomplete_known_uri_values }.not_to raise_error
    end

    it 'should return global matches when there is no predicate' do
      get :autocomplete_known_uri_values, :term => ''
      assigns[:known_uris].should == [ ]
      get :autocomplete_known_uri_values, :term => 'male'
      assigns[:known_uris].should == [ @male, @female ]
      get :autocomplete_known_uri_values, :term => 'http://'
      assigns[:known_uris].should == KnownUri.values.sort
    end

    it 'should return a list of visible allowed values when given a predicate' do
      get :autocomplete_known_uri_values, :term => '', :predicate_known_uri_id => @sex.id
      assigns[:known_uris].should == [ @male, @female ]
      @male.update_column(:visibility_id, Visibility.invisible.id)
      get :autocomplete_known_uri_values, :term => '', :predicate_known_uri_id => @sex.id
      assigns[:known_uris].should == [ @female ]
      @male.update_column(:visibility_id, Visibility.visible.id)
    end

    it 'should allow searches within values' do
      get :autocomplete_known_uri_values, :term => 'female', :predicate_known_uri_id => @sex.id
      assigns[:known_uris].should == [ @female ]
      # note that only values from this predicate are getting returned
      get :autocomplete_known_uri_values, :term => 'http://', :predicate_known_uri_id => @sex.id
      assigns[:known_uris].should == [ @male, @female ]
    end

    it 'should be able to search for non-visible metadata' do
      last_term = KnownUri.metadata.last
      get :autocomplete_known_uri_values, :term => 'female', :predicate_known_uri_id => @sex.id
      assigns[:known_uris].should == [ @female ]
      @female.update_column(:visibility_id, Visibility.invisible.id)
      get :autocomplete_known_uri_values, :term => 'female', :predicate_known_uri_id => @sex.id
      assigns[:known_uris].should == [ @female ]
      @female.update_column(:visibility_id, Visibility.visible.id)
    end
  end

end
