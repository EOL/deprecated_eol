desc 'Run and save a benchmark'
task :benchmark do
  site_is_not_running = `curl http://localhost:3000 2>&1`.include?("couldn't connect to host")
  if site_is_not_running
    puts "Couldn't hit the site @ http://localhost:3000, please start an application server"
    exit
  end

  benchmark_name = Time.now.strftime '%Y-%m-%d_%H:%M:%S'
  benchmark_name << "_#{ ENV['NAME'].gsub(' ','_') }" if ENV['NAME']
  cmd = "bong '#{ benchmark_name }'"
  puts cmd
  puts `#{ cmd }`
  puts "\nTo view this benchmark again, $ bong '#{ benchmark_name }' -r log/httperf-report.yml" 
end

desc 'List names of saved benchmarks'
task :benchmarks do
  data = YAML.load_file('log/httperf-report.yml')
  data.keys.sort.each {|key| puts key }
end

namespace :benchmark do

  desc 'Runs bong-log-viewer for viewing/comparing saved benchmarks'
  task :viewer do
    begin
      exec 'bong-log-viewer'
    rescue Errno::ENOENT
      puts "bong-log-viewer not found, sudo gem install openrain-bong-log-viewer"
    end
  end

end
