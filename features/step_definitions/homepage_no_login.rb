When /^look at images gallery$/ do
  @images ||= []
  image_sources = page.all(:xpath, "//table[@id='top-photos-table']//img[contains(@src, '_medium.jpg')]").map {|img| img.node.attribute(:src)}.join(" ")
  @images << image_sources
end

Then /^I see that some images are different$/ do
  @images[1].should_not == @images[0]
end
