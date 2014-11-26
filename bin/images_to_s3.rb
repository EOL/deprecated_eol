require 'aws-sdk'
["IMAGE_PATH", "AWS_EOL_BUCKET"].each do |key|
  raise  "#{key} not specified" unless ENV[key]
end
require 'find'
def timestamp_puts(str)
  STDOUT.flush
  puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}: #{str}"
end
path = ENV["IMAGE_PATH"]
s3 = AWS::S3.new
bucket = s3.buckets[ENV["AWS_EOL_BUCKET"]]
files = Find.find(path).
  select { |p| p !~ /.sha\d\z/ and not FileTest.directory?(p) }
timestamp_puts "START, processing #{files.length} files."
exists = 0
files.each_with_index do |file, index|
  # We only want to store the name from the content folder onward:
  name = file.sub(/\A.*(?=content\/\d\d\d\d\/)/, '')
  obj = bucket.objects[name]
  if obj.exists?
    exists += 1
  elsif exists > 0
    timestamp_puts "SKIPPED #{exists} FILES (already exist)"
    exists = 0 # Don't show warning again.
  end
  obj.write(file: file, acl: :public_read)
  # Show some files (we generally have 6 versions of each file, so this is
  # roughly every tenth data object)...
  if (index % 60) == 0
    timestamp_puts "(##{index}/#{files.length}) #{name}"
    puts "  -> #{obj.public_url.to_s.sub(/https/, 'http')}"
  end
end
timestamp_puts "COMPLETE."
