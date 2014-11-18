require 'aws-sdk'
["IMAGE_PATH", "AWS_EOL_BUCKET"].each do |key|
  raise  "#{key} not specified" unless ENV[key]
end
require 'find'
path = ENV["IMAGE_PATH"]
s3 = AWS::S3.new
bucket = s3.buckets[ENV["AWS_EOL_BUCKET"]]
files = Find.find(path).
  select { |p| f !~ /.sha\d\z/ and not FileTest.directory?(p) }
puts "Total of #{files.length} files to process."
files.each_with_index do |file, index|
  # We only want to store the name from the content folder onward:
  name = file.sub(/\A.*(?=content\/\d\d\d\d\/)/, '')
  obj = bucket.objects[name]
  obj.write(file: file, acl: :public_read)
  # Show some files (we generally have 6 versions of each file, so this is
  # roughly every tenth data object)...
  if (index % 60) == 0
    print Time.now.strftime("%Y-%m-%d %H:%M:%S")
    puts ": (##{index}/#{files.length}) #{name}"
    puts "  -> #{obj.public_url.to_s.sub(/https/, 'http')}"
  end
end
