require 'aws-sdk'
["IMAGE_PATH", "AWS_EOL_BUCKET"].each do |key|
  raise  "#{key} not specified" unless ENV[key]
end
require 'find'
path = ENV["IMAGE_PATH"]
s3 = AWS::S3.new
bucket = s3.buckets[ENV["AWS_EOL_BUCKET"]]
files = Find.find(path).select { |p| ! FileTest.directory?(p) }
files.select { |f| f !~ /.sha\d\z/ }.each do |file|
  # We only want to store the name from the year onward:
  name = file.sub(/\A.*(?=\d\d\d\d\/\d\d\/\d\d)/, '')
  puts "Writing: #{name}"
  obj = bucket.objects[name]
  obj.write(file: file, acl: :public_read)
  puts "  -> #{obj.public_url.to_s.sub(/https/, 'http')}"
end
