# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# This class is a bit ugly around the edges -- I'm not quite sure how to
# architect it, yet.

require 'optimus'
require 'transformers/column_calculator'
require 'transformers/row_filter'

module Optimus
  class StimtimesWriter
    include Transformers
    
    @@computed_columns = []
    @@counter_columns = []
    @@copydown_columns = []
    @@runs = 0
    @@run_column = ''
    @@output_files = []
    
    def initialize(argv)
      # Look through our necessary class variables and do some odd stuff
      edata = Optimus::Data.new
      argv.each do |filename|
        File.open(filename, 'r') do |f|
          reader = Optimus::Reader.new(f)
          edata.merge!(reader.optimus_data)
        end
        
        @calc = ColumnCalculator.new
        @calc.data = edata
        @@computed_columns.each do |coldata|
          @calc.computed_column *coldata
        end
        
        @@counter_columns.each do |coldata|
          @calc.counter_column *coldata
        end
        
        @@copydown_columns.each do |coldata|
          @calc.copydown_column *coldata
        end
        

        @@output_files.each do |output|
          filename, filter, output_column = output
          self.output_file(filename, filter, output_column)
        end
      end
    end

    def output_file(filename, filter, output_column)
      File.open(filename, 'w') do |file|
        filtered = RowFilter.new(@calc, filter)
        
        1.upto(@@runs) do |run|            
          run_rows = filtered.find_all {|row| row[@@run_column].to_s == run.to_s}.to_a
          vals = run_rows.map { |r| r[output_column] }
          if vals.size == 0
            file.puts "**"
          else
            file.puts((vals << "*").join(' '))
          end
        end
      end
    end
    
    class << self
      def computed_column(*args)
        @@computed_columns << args
      end
      
      def counter_column(*args)
        @@counter_columns << args
      end
      
      def copydown_column(*args)
        @@copydown_columns << args
      end
      
      def runs(runs)
        @@runs = runs
      end
      
      def run_column(col_name)
        @@run_column = col_name
      end
      
      def output_file(*args)
        @@output_files << args
      end
    end
  end
end