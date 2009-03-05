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

# Add some methods to the Array class
class Array
  def to_h
    Hash[*self.enum_for(:each_with_index).collect { |v,i|
      [i, v]
    }.flatten]
  end
end

class SpendPerDay

  # Define which day is the payday
  PAYDAY = 25
  
  def initialize(bank_statement)
    # Empty data array
    @transactions = []
    
    # Iterate over the bank statement
    CSV.open(bank_statement, 'r', "\t") do |row|
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
    @code7_theme = {
       :colors            => %w('#7CAF3C'),
       :marker_color      => '#B8D395',
       :font_color        => '#2F5C1A',
       :background_colors => %w(white #D8FFD2)
    }  
  end

  def generate_graphs
    balance_graph
    spend_per_day_graph
  end

  #
  # Generate the Balance graph
  #
  def balance_graph(file = 'balance.png')
     
    # Create line graph object
    g = Gruff::Line.new 500 
    
    # Use the Code7 theme
    g.theme = @code7_theme
    
    # Add the dataset
    g.data('Account balance', @transactions.map{|t| t[:balance].to_i })
    
    # Get the middle transaction
    middle_pos = (@transactions.length / 2)
    
    # Add the last date as a label
    g.labels = {
      0 => @transactions.first[:log_date].to_s,
      middle_pos => @transactions[middle_pos][:log_date].to_s,
      @transactions.length - 1 => @transactions.last[:log_date].to_s
    }
    
    # Set the minimum value to 0 for a better overview
    g.minimum_value = 0
    
    # Set the marker line count
    g.marker_count = 10
    
    # Hide the dots
    g.hide_dots = true
    
    # Write the graph to disk
    g.write(file)
  end
  
  #
  # Generate the "Spend Per Day" graph
  #
  def spend_per_day_graph(file = 'spend-per-day.png')
    
    # First we need to populate the dataset
    spend_per_day_data  = []
    spend_per_day_dates = []
    
    @transactions.each_with_index do |transaction, index|
      log = transaction[:log_date]
      payday = Date.new log.year, log.month, PAYDAY
      
      # Check if the payday is in the weekend
      if payday.cwday > 5
        payday = Date.new log.year, log.month, PAYDAY - (payday.cwday - 5)
      end
      
      # Check if it is before or after payday
      if log >= payday
        if log.month == 12
          next_payday = Date.new log.year + 1, 1, PAYDAY
        else
          next_payday = Date.new log.year, log.month + 1, PAYDAY
        end
      elsif log < payday
        next_payday = payday
      end
      
      # Calculate the number of days until the next payday
      days_to_go = (next_payday - log).to_i
      
      # Not interested in the peaks around payday
      if log.day < 23 || log.day > 25
        # Add the ammount that can be spent per day to the data array
        spend_per_day_data << (transaction[:balance] / days_to_go).to_i
        spend_per_day_dates << transaction[:log_date].to_s
      end
    end
    
    # Create line graph object
    g = Gruff::Line.new 500
    
    # Use the Code7 theme
    g.theme = @code7_theme
    
    # Add the dataset
    g.data('Spend Per Day', spend_per_day_data)
    
    # Get the middle transaction
    middle_pos = (spend_per_day_dates.length / 2)
    
    # Add the last date as a label
    g.labels = {
      0 => spend_per_day_dates.first,
      middle_pos => spend_per_day_dates[middle_pos],
      spend_per_day_data.length - 1 => spend_per_day_dates.last
    }
    
    # Set the minimum value to 0 for a better overview
    g.minimum_value = 0
        
    # Set the marker line count
    g.marker_count = 10
    
    # Hide the dots
    g.hide_dots = true
    
    # Write the graph to disk
    g.write(file)
  end
end