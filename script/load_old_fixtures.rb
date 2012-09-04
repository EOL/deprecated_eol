Dir['spec_10/fixtures/*.{yml,csv}'].each do |f|
  puts f
  Fixtures.create_fixtures(File.dirname(f), File.basename(f, '.*'))
end
