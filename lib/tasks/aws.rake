desc 'Move all images under IMAGE_PATH to Amazon S3'
task :images_to_s3 => :environment do
  ["IMAGE_PATH", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
   "AWS_EOL_BUCKET"].each do |key|
    raise  "#{key} not specified" unless ENV[key]
  end
  # Allow finding files:
  require 'Find'
  s3 = AWS::S3.new
  bucket = s3.buckets[ENV["AWS_EOL_BUCKET"]]
  while count > 0 do
    files = Find.find(ENV["IMAGE_PATH"]).select { |p| ! FileTest.directory?(p) }
    files.each do |file|
      bucket.objects["images"].write(file: file)
    end
  end
end
