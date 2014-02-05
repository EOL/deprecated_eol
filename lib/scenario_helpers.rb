# For loading scenarios. 
module ScenarioHelpers

  def load_foundation_cache
    truncate_all_tables
    load_scenario_with_caching(:foundation)
  end

  def load_scenario_with_caching(name)
    loader = EOL::ScenarioLoader.new(name, EOL::Db.all_connections)
    # TODO - this may want to check if it NEEDS loading, here, and then truncate the tables before proceeding, if it
    # does.
    loader.load_with_caching
  end

end
