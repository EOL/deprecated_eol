require 'net/http'
require 'uri'

# put the URLs to test below separated by spaces in between curly brackets
urls_to_test = $TEST_URLS || []

# how long to wait in seconds before assuming we will get no response
timeout_seconds = 5

puts ""
puts "EOL Website Check"
puts "Date: " + Time.now.to_s
puts "Timeout check in seconds: " + timeout_seconds.to_s
puts "--------------------------"

urls_to_test.each do |url|
     puts "Testing: " + url
     begin
         resp=Timeout::timeout(timeout_seconds) {Net::HTTP.get_response(URI.parse(url))}
         if resp
           puts "Successful Response: " + url
         else
           puts "******Bad response: " + url
         end
     rescue TimeoutError 
          puts "******Timed out: " + url + " (response took more than " + timeout_seconds.to_s + " seconds)"
     end
     puts ""
end

puts "--------------------------"
