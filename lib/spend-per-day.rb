#!/usr/bin/ruby

# Require RubyGems and the Gruff library for graphing
require 'rubygems'
require 'gruff'

# Require the built in CSV parser (Slow but OK for my purposes)
require 'csv'

# Require the date library
require 'date'

# Require the enumerator library used in the to_h method
require 'enumerator'

# Add the to_h method
class Array
  def to_h
    Hash[*self.enum_for(:each_with_index).collect { |v,i|
      [i, v]
    }.flatten]
  end
  
  def sum
    inject( nil ) { |sum,x| sum ? sum+x : x } 
  end
  
  def mean
    sum.to_f / size
  end
  
  def floor_mean(num = 1)
    mean.to_i / num * num if num > 0
  end
end

# Define which day is the payday
PAYDAY = 25

# Empty data array
@transactions = []

# Iterate over the bank statement
CSV.open(File.dirname(__FILE__) + '/../bank_statement.txt', 'r', "\t") do |row|
  @transactions << {
    # Parse the log date, interpret 2-digit years as 20XX
    :log_date => Date.parse(row[0], true),
    
    # Parse the transaction date, interpret 2-digit years as 20XX
    :transaction_date => Date.parse(row[1], true),
    
    # Parse the event string
    :event => row[2].strip.capitalize,

    # Handle the amount
    :amount => row[4].delete(' ').tr(',', '.').to_f,
    
    # Get the account balance
    :balance => row[5].delete(' ').tr(',', '.').to_f
  }
end

# Reverse the transactions
@transactions.reverse!

# Define the Code7 theme
code7_theme = {
   :colors            => %w('#7CAF3C'),
   :marker_color      => '#7CAF3C',
   :font_color        => '#2F5C1A',
   :background_colors => %w(white #D8FFD2)
 }

#
# Generate the Balance graph
#

# Create a 500px wide line graph object
g = Gruff::Line.new(1000)

# Use the Code7 theme
g.theme = code7_theme

# Add the dataset
g.data('Account balance', @transactions.map{|t| t[:balance].to_i })

# Set the minimum value to 0 for a better overview
g.minimum_value = 0

# Set the marker line count
g.marker_count = 10

g.hide_dots = true


# Write the graph to disk
g.write('balance.png')


#
# Generate the "Spend Per Day" graph
#

spend_per_day_data = []

@transactions.each do |transaction|
  log = transaction[:log_date]
  payday = Date.new log.year, log.month, PAYDAY
  
  # Check if the payday is in the weekend
  if payday.cwday > 5
    payday = Date.new log.year, log.month, PAYDAY - (payday.cwday - 5)
  end
  
  # Check if it is before or after payday
  if log >= payday
    next_payday = Date.new log.year, log.month + 1, PAYDAY
  elsif log < payday
    next_payday = payday
  end
  
  # Calculate the number of days until the next payday
  days_to_go = (next_payday - log).to_i
  
  # Not interested in the peaks around payday
  if log.day < 23 || log.day > 25
    # Add the ammount that can be spent per day to the data array
    spend_per_day_data << (transaction[:balance] / days_to_go).to_i
  end
end

# Create a 500px wide line graph object
g = Gruff::Line.new(1000)

# Use the Code7 theme
g.theme = code7_theme

# Add the dataset
g.data('Spend Per Day', spend_per_day_data)

# Set the minimum value to 0 for a better overview
g.minimum_value = 0

# Set the maximum value to the mean value, floored to closest thousand
g.maximum_value = spend_per_day_data.floor_mean(1000)

# Set the marker line count
g.marker_count = 10

g.hide_dots = true

# Write the graph to disk
g.write('spend-per-day.png')