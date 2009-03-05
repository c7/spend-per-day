task :default => :generate_and_open

task :test do
  require File.dirname(__FILE__) + '/test/all_tests.rb'  
end

task :generate_and_open do
  # Require the script
  require File.dirname(__FILE__) + '/lib/spend-per-day'
  
  # Open the images
  `open balance.png spend-per-day.png`
end