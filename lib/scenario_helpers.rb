# For loading scenarios.

# TODO - why isn't this in lib/eol_scenarios/ ?

include TruncateHelpers

module ScenarioHelpers

  def load_foundation_cache
    truncate_all_tables
    load_scenario_with_caching(:foundation)
  end

  # TODO - this may want to check if it NEEDS loading, here, and then truncate
  # the tables before proceeding, if it does.
  def load_scenario_with_caching(name)
    EOL::ScenarioLoader.load_with_caching(name)
  end

end
