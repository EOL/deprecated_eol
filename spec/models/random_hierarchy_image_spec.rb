require File.dirname(__FILE__) + '/../spec_helper'

describe RandomHierarchyImage do

  before(:all) do
    load_foundation_cache
    @old_value = $HOMEPAGE_MARCH_RICHNESS_THRESHOLD
    $HOMEPAGE_MARCH_RICHNESS_THRESHOLD = nil # The foundation scenario doesn't include metrics.
  end

  after(:all) do
    $HOMEPAGE_MARCH_RICHNESS_THRESHOLD = @old_value
  end

  it 'should return random set of published images' do
    random_images = RandomHierarchyImage.random_set(RandomHierarchyImage.count, Hierarchy.default)
    random_images.count.should == 4 # there are actually 5 RandomHierarchyImage records loaded in foundation
                                    # but one is not in the default hierarchy and not returned by random_set
    tc = random_images.first.taxon_concept
    tc.update_attributes(published: false) # we should no longer see the image for this unpublished taxon
    random_images = RandomHierarchyImage.random_set(RandomHierarchyImage.count, Hierarchy.default)
    random_images.count.should == 3
    random_images.select{|ri| ri.taxon_concept == tc}.should be_empty
    tc.update_attributes(published: true) # the image for this published taxon should show up again
    random_images = RandomHierarchyImage.random_set(RandomHierarchyImage.count, Hierarchy.default)
    random_images.count.should == 4
    random_images.select{|ri| ri.taxon_concept == tc}.should_not be_empty
  end

end
