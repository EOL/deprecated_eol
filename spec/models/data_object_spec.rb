require File.dirname(__FILE__) + '/../spec_helper'

describe DataObject do
  it 'should have a default rating of 0.0' do
    d = DataObject.new
    d.data_rating.should eql(0.0)
  end

  it 'should create new rating' do
    UsersDataObjectsRating.count.should eql(0)

    d = DataObject.gen
    u = User.gen
    d.rate(u,5)

    UsersDataObjectsRating.count.should eql(1)
    d.data_rating.should eql(5.0)
    r = UsersDataObjectsRating.find_by_user_id_and_data_object_id(u.id, d.id)
    r.rating.should eql(5)
  end

  it 'should generate average rating' do
    d = DataObject.gen
    u1 = User.gen
    u2 = User.gen
    d.rate(u1,4)
    d.rate(u2,2)
    d.data_rating.should eql(3.0)
  end

  it 'should update existing rating' do
    d = DataObject.gen
    u = User.gen
    d.rate(u,1)
    d.rate(u,5)
    d.data_rating.should eql(5.0)
    UsersDataObjectsRating.count.should eql(1)
    r = UsersDataObjectsRating.find_by_user_id_and_data_object_id(u.id, d.id)
    r.rating.should eql(5)
  end
end