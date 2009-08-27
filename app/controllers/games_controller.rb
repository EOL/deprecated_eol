class GamesController < ApplicationController
  
  layout 'main'
  
  def identify_the_image
     
     @num_images=5
     
     # original ordering of random taxa
     @taxa  = RandomHierarchyImage.random_set(@num_images, @session_hierarchy)
     
     # now scramble the order into an array
     @random_order = Array.new
     
     while @random_order.length < @num_images do
       
       # get a random number from 0..num_images
       random_number=rand(@num_images)
       
       # check to see if we've already included that number in our random array, otherwise add it
       @random_order << random_number unless @random_order.include? random_number
       
     end
     
  end
  
end
