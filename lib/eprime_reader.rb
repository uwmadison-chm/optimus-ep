# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  
  # A class that should open any type of E-Prime text file and read it into
  # an E-Prime data structure.
  # This class isn't yet used anywhere.
  class Reader
    
    attr_reader :type, :parser, :input
    attr_accessor :options
    
    TYPES = {:log => LogfileParser, :excel => ExcelParser, :eprime => EprimetabParser}
    def initialize(input = nil, options = {})
      @options = options || {}
      set_input(input) unless input.nil?
    end
    
    def input=(input)
      set_input(input)
    end
    
    def eprime_data
      @eprime_data ||= @parser.to_eprime
      return @eprime_data
    end
    
    def options=(options)
      @options = options || {}
      set_parser!
    end
    
    private
    def set_input(input)
      @input = input
      read_input!
    end
    
    # Reads the input, sets @type and @parser.
    def read_input!
      begin
        set_type(@input)
      rescue Exception => e
        raise UnknownTypeError.new(e.message)
      end
    end
    
    
    # Sets @type to one of Eprime::Reader::TYPES or raises an Eprime::UnknownTypeError
    # Does not change file position.
    def set_type(file)
      @file = file
      original_pos = @file.pos
      @file.rewind
      first_lines = Array.new
      # We can tell what kind of file this is from the first two lines
      # If there aren't two lines, this can't be a good file.
      2.times do
        first_lines << @file.gets
      end
      @file.pos = original_pos
      @type = determine_file_type(first_lines)
      if @type.nil?
        raise UnknownTypeError.new("Can't determine the type of #{file.path}")
      end
      set_parser!
    end
    
    def set_parser!
      @eprime_data = nil
      return unless @type && TYPES[@type]
      @parser = TYPES[@type].new(@file, @options)
    end
    
    # Determines the type of an eprime file, based on its first two lines.
    # Returns one of [:log, :eprime_csv, :excel_csv, nil]
    def determine_file_type(first_lines)
      # Log files start with *** Header Start ***
      #
      # Excel files have a filename on the first line (no tabs); the second line
      # contains at least three elements, tab-delimted
      #
      # eprime CSV files will have at least three tab-delimited elements on the first line
      
      if first_lines[0].index("*** Header Start ***")
        return :log
      elsif (first_lines[0]["\t"].nil? and first_lines[1].split("\t").size >= 3)
        return :excel
      elsif (first_lines[0].split("\t").size >= 3 and first_lines[1].split("\t").size >= 3)
        return :eprime
      end
      # Don't know? Return nil.
      return nil
    end
  end
end