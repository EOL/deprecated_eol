# Bring out 'yer dead!  Bring out 'yer dead!
#
# This is a module for all of EOL's custom exceptions.  Remember that it is superior to raise exceptions and catch
# them than it is to use return values that signify success and failure and parse them.
module EOL
  module Exceptions
    class CannotMergeClassificationsToSelf < StandardError; end
    class ClassificationsLocked < StandardError; end
    class CollectionJobRequiresScope < StandardError; end
    class EmptyHierarchyFlattened < StandardError; end
    class FailedToCreateTag < StandardError; end
    class HarvestPauseTimeExceeded < StandardError; end
    class InvalidCollectionItemType < StandardError; end
    class MaxCollectionItemsExceeded < StandardError; end
    class MustBeLoggedIn < StandardError; end
    class NoCollectionsApply < StandardError; end
    class NoItemsSelected < StandardError; end
    class ObjectNotFound < StandardError; end
    class OnlyUsersCanCreateCommunitiesFromCollections < StandardError; end
    class OpenAuthBadResponse < StandardError; end
    class OpenAuthMissingConnectedUser < StandardError; end
    class OpenAuthUnauthorized < StandardError; end
    class Pending < StandardError; end
    class ProvidersMatchOnMerge < StandardError; end
    class ApiException < StandardError; end
    class SecurityViolation < StandardError
      attr_accessor :flash_error_key, :flash_error_scope
      attr_writer :flash_error
      # TODO - While the flash_error_key is nice, it's not flexible, since you can't pass in interpolated variables.
      # Review and re-factor... I suspect we could generalize this code a bit as it's used in (many) controllers.
      def initialize(msg = nil, flash_error_key = :default, flash_error_scope = [:exceptions, :security_violations])
        if msg.is_a?(Array)
          super(msg[0])
          @flash_error_key = msg[1]
          @flash_error_scope = msg[2]
        else
          super(msg)
        end
        @flash_error_key ||= flash_error_key
        @flash_error_scope ||= flash_error_scope
      end

      def flash_error
        @flash_error ||= I18n.t(flash_error_key, :scope => flash_error_scope,
                                :default => I18n.t('exceptions.security_violations.default'))
      end
    end
    class SparqlDataEmpty < StandardError; end
    class TooManyDescendantsToCurate < StandardError; end
    class UnknownFeedType < StandardError; end
    class WrongCurator < StandardError; end
  end
end
