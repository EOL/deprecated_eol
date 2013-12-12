
reads = 1000
num_keys = 100

puts "++ Turning off logging for this test."

  keys = []
  num_keys.times do |i|
    keys << "some/strange/path/to_#{i}"
    Rails.cache.mute { Rails.cache.delete(keys.last) }
  end

Benchmark.bm do |x|

  x.report("Memcached") do
    (reads + 1).times do # The first one is a write
      keys.each do |key|
        Rails.cache.mute do
          Rails.cache.fetch(key) do
            "Some string for key #{key}"
          end
        end
      end
    end
  end

end
