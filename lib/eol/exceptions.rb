# Bring out 'yer dead!  Bring out 'yer dead!
#
# This is a module for all of EOL's custom exceptions.  Remember that it is superior to raise exceptions and catch
# them than it is to use return values that signify success and failure and parse them.
module EOL
  module Exceptions
    class FailedToCreateTag < StandardError; end
    class InvalidCollectionItemType < StandardError; end
    class MaxCollectionItemsExceeded < StandardError; end
    class MustBeLoggedIn < StandardError; end
    class NoCollectionsApply < StandardError; end
    class ObjectNotFound < StandardError; end
    class OnlyUsersCanCreateCommunitiesFromCollections < StandardError; end
    class OpenAuthBadResponse < StandardError; end
    class OpenAuthMissingAuthorizeUri < StandardError; end
    class Pending < StandardError; end
    class SecurityViolation < StandardError; end
    class UnknownFeedType < StandardError; end
    class WrongCurator < StandardError; end
  end
end

