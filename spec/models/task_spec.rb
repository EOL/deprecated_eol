require 'spec_helper'

describe Task do

  before(:all) do
    @task_name_string = 'Something new'
    @task_name = TaskName.gen(:description => @task_name_string)
  end

  it 'should re-calculate the frequency of its name when created' do
    @task_name.reload
    start_frequency = @task_name.frequency
    Task.gen(:task_name => @task_name)
    Task.gen(:task_name => @task_name)
    Task.gen(:task_name => @task_name)
    @task_name.reload
    @task_name.frequency.should == 3 # Because we just made three of them...
  end

end
