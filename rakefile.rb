task :default => :generate_and_open

task :test do
  require File.dirname(__FILE__) + '/test/all_tests.rb'  
end

task :generate_and_open do
  # Require the script
  require File.dirname(__FILE__) + '/lib/spend-per-day'
  
  # Initialize the object based on the bank_statement.txt file
  # that I get from the overview page on my swedbank.se account
  spd = SpendPerDay.new 'bank_statement.txt' 
  
  # Generate the graphs
  spd.generate_graphs
  
  # Open the images
  `open balance.png spend-per-day.png`
end