# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison


# This class is not yet ready for prime-time -- it needs specs and such before it can really
# be considered done. There's also no error checking. It's horrid at the moment.
#
# You have been warned.

module Eprime
  class Reader
    class TabfileParser
      def initialize(file, options = {})
        @file = file
        @skip_lines = options[:skip_lines] || 0
      end
      
      def to_eprime
        lines = @file.readlines
        @skip_lines.times do
          lines.shift
        end
        
        columns = lines.shift.split("\t").map {|elt| elt.strip }
        expected_size = columns.size
        data = Eprime::Data.new(columns)
        current_line = @skip_lines+1
        lines.each do |line|
          current_line += 1
          row = data.add_row
          col_data = line.split("\t").map {|e| e.strip }
          if col_data.size != expected_size
            raise DamagedFileError.new("In #{@file.path}, line #{current_line} should have #{expected_size} columns but had #{col_data.size}.")
          end
          col_data.each_index do |i|
            row[i] = col_data[i]
          end
        end
        return data
      end
    end
  end 
end