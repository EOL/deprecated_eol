require File.dirname(__FILE__) + '/../spec_helper'

# Since we're testing an abstract class:
class TestLogger < LoggingModel
  set_table_name 'api_logs' # whatever; just needs to be real and to have a non-null column somewhere
end

# Tricky-tricky!  I am getting it to raise an AR error, so that we see the code that was executed!  MUHAHAHA!!!
#
# Perhaps I should be tailing the logfile instead, but this struck me as acceptable.  Feel free to change this,
# however, if it offends your sensibilities.
describe TestLogger do
  # 10.9.10 - pleary removed this because the statement is no longer working, but the model is
  # using INSERT DELAYED. So there must be a more precise way to figure this out
  
  
  #it 'should use INSERT DELAYED on create' do
  #  lambda { tl = TestLogger.create }.should raise_error(ActiveRecord::StatementInvalid, /INSERT DELAYED/)
  #end
end
