# An agent is any person, project or entity that is associated with EOL indexed
# data.  Example of agents include projects, authors, and photographers.
# Any given data object can be associated with multiple agents, each agent
# assigned a differing role based on their association to the associated data object.

# All Users also have an associated agent, as the Agent is currently the entity which
# is cited in the site. We can at some point remove this duplication.
# TODO: when the User name is updated, is the agent name updated too?
class Agent < ActiveRecord::Base
  has_one :user

  # Because of the tables pluralization these may trip you up sometimes
  has_many :agents_synonyms
  has_many :synonyms, through: :agents_synonyms

  has_and_belongs_to_many :data_objects

  # Callbacks
  before_save :blank_not_null_fields

   # Alias some partner fields so we can use validation helpers
  alias_attribute :project_name, :full_name
  alias_attribute :url, :homepage

  # To make users be able to change species pages (add a common name for example)
  # we have create an agent bypassing all the usual safety checks
  def self.create_agent_from_user(thename)
    Agent.with_master do
      agent_id = Agent.connection.insert(EOL::Db.sanitize_array(
        ["INSERT INTO agents (full_name) VALUES (?)", thename]))
      return Agent.find(agent_id)
    end
    return nil
  end

  # Singleton class variable, so we only ever look it up once per thread:
  def self.iucn
    cached_find(:full_name, 'IUCN')
  end

  def self.catalogue_of_life
    cached_find(:full_name, 'Catalogue of Life')
  end

  def self.col
    self.catalogue_of_life
  end

  def self.gbif
    cached_find(:full_name, 'Global Biodiversity Information Facility (GBIF)')
  end

  def self.ncbi
    cached_find(:full_name, 'National Center for Biotechnology Information')
  end

  def self.boa
    cached_find(:full_name, 'Biology of Aging')
  end

  def shortened_full_name
    return self.full_name.strip[0..50]
  end

protected

  # Set these fields to blank because insistence on having NOT NULL columns on things that aren't populated
  # until certain steps.
  def blank_not_null_fields
    self.homepage       ||= ''
    self.full_name      ||= ''
    self[:logo_url]     ||= ''
    self.homepage = 'http://' + self.homepage if self.homepage != '' && (self.homepage[0..6] != 'http://' && self.homepage[0..7] != 'https://')
  end

end
