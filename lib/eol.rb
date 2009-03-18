#
# top level EOL class
#
# we might want to use this for global configuration options or ... anything
#
# it's also useful to have around for namespacing other classes/modules 
# in the EOL:: namespace
#
class EOL
  
  # used to check if a user agent is a robot or not
  def self.allowed_user_agent?(user_agent)
    if user_agent.downcase =~ /googlebot|slurp/
      return false
    else
      return true
    end
  end
  
end