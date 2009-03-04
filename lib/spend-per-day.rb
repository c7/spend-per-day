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
end

# Empty data array
@transactions = []

# Iterate over the bank statement
CSV.open('../bank_statement.txt', 'r', "\t") do |row|
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

#
# Generate the Balance graph
#

# Create a 500px wide line graph object
g = Gruff::Line.new(500)

# Create a Code7 theme
g.theme = {
   :colors            => %w('#7CAF3C'),
   :marker_color      => '#7CAF3C',
   :font_color        => '#2F5C1A',
   :background_colors => %w(white #D8FFD2)
 }

# Add the dataset
g.data('Account balance', @transactions.map{|t| t[:balance].to_i })

# Write the graph to disk
g.write('balance.png')

# Open the image (TEMPORARY)
`open balance.png`