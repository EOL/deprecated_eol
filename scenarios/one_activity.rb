# Creates one activity, for use in testing the functionality of scenarios themselves.  It is UP TO YOU to clear out
# this table before-hand, if you need to.
#
# Note I chose Activity because it was the most minimal model I could find AND that didn't cache all of its values.
Activity.find_or_create('just one activity')
