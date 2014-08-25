Style Guide for EOL
===================

Style
-----

* Prefer #first to #[0].
* Prefer #last to #[-1].

Exemplar files
--------------

There are several exemplar files in the code marked with EXEMPLAR keyword at
the beginning. They aim to give idea how do we want to implement best practices
and and follow code styles.

Controller
# You should:
# * follow this pattern (of thin controller methods) as closely as possible.
#   Public methods should follow REST/CRUD, everything else should be kept
#   private.
# * Try to keep all of your access control here in the controller.
# * Move as much logic as you can to the models.


# - Feature Spec (for testing the full stack)
#
# You should:
#
# * Avoid using mocks and stubs (except WebMock).
# * Test all the basic CRUD workflows.
# * DEFINITELY test a "render" as part of the Read.
# * Test any resource-specific edge-cases (though this is lower priority).
# * MINIMIZE your feature specs! These are expensive.
# * NOTE any exceptions.
#
# NOTE that we are not testing for simple "is here" or "is not here", as those
# types of tests belong in a view spec.
#
# NOTE There is no spec for destroying or deleting a CP, because we don't
# allow it.
  
  # This is as close as we get to a "read" spec, here, because specifics
  # belong in a view spec, but having a feature spec ensure that the full
  # stack renders is actually useful.
