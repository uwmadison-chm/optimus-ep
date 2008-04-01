# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  class Reader
    
    # Reads and parses E-Prime log files (the ones that start with 
    # *** Header Start ***) and transforms them into an Eprime::Data structure
    
    class LogFileParser
      # Handles parsing eprime log files, which are essentially a blow-by-blow
      # log of everything that happened during an eprime run.

      FRAME_START = '*** LogFrame Start ***'
      FRAME_END = '*** LogFrame End ***'
      HEADER_START = '*** Header Start ***'
      HEADER_END = '*** Header End ***'
      LEVEL_KEY = 'Level'
      LEVEL_NAME_KEY = 'LevelName'
      
      attr_reader :frames
      attr_reader :levels
      attr_reader :top_level
      attr_reader :skip_columns
      
      # Valid things for the options hash:
      #   :columns => an array of strings, predefining the expected columns 
      #               (and their order)
      #   :force => true, if you want to ignore things such as column added
      #               warnings and if the file is incomplete
      
      def initialize(file, options = {})
        @columns = options[:columns]
        @force = options[:force]
        @file = file
        @levels = [''] # The 0 index should be blank.
        @top_level = 0 # This is the level of the frame that'll generate output rows
        @skip_columns = {} # A hash of columns we *don't* want to add -- just define the strings
      end
      
      def make_frames!
        read_levels(@file)
        @frames = frameify(@file)
        set_parents!
        set_counters!
      end
      
      def to_eprime
        begin
          if @frames.nil? or @frames.empty?
            make_frames!
          end
        rescue Exception => e
          unless @force
            raise e
          end
        end
        if @columns
          data = Eprime::Data.new(@columns)
        else
          data = Eprime::Data.new
        end
        self.top_frames.each do |frame|
          row = data.add_row
          frame.columns.each do |column, value|
            begin
              # Do a check for columns to skip -- this will happen in the case
              # where you have Procedure[Session] and Procedure[Task] -- we
              # shouldn't have Procedure, in that case.
              unless @skip_columns[column]
                row[column] = value
              end
            rescue Exception => e
              unless @force
                raise e
              end
            end
          end
        end
        return data
      end
      
      def top_frames
        return frames.find_all { |frame| frame.level == @top_level }
      end
      
      # Define this as a column we *should not* include in out output.
      def skip_column(col_name)
        @skip_columns[col_name] = true
      end
      
      private
      # iterate over each line, strip it, look for *** LogFrame Start *** and
      # *** LogFrame End *** -- the content between those goes into a frame array.
      # If we start a frame but don't end it, raise a DamagedFileError
      def frameify(file)
        in_frame = false
        frames = []
        frame = Frame.new(self)
        level = 0
        file.each_line do |line|
          # TODO? Refactor this out into its own private function
          l_s = line.strip
          key, val = l_s.split(/: */, 2) # There isn't always a space, and values can contain colons
          
          if !in_frame
            if key == LEVEL_KEY
              frame.level = val.to_i
              @top_level = frame.level if frame.level > @top_level
            elsif key == FRAME_START
              in_frame = true
            end
          else
            if key == FRAME_END
              in_frame = false
              frames << frame
              frame = Frame.new(self)
            else
              # Add the data to our frame
              # One more special thing: Experiment gets renamed ExperimentName. WTF?
              key = "ExperimentName" if key == "Experiment"
              frame[key] = val
            end
          end
        end
        raise DamagedFileError.new("Last frame never closed in #{file.path}") if in_frame
        return frames
      end
      
      # Reads through the header and resets the file to its starting position
      def read_levels(file)
        in_header = false
        file.each_line do |line|
          l_s = line.strip
          key, val = l_s.split(': ')
          if !in_header
            if key == HEADER_START
              in_header = true
            end
          else
            if key == HEADER_END
              file.rewind
              return # Get out of this function!
            else
              if key == LEVEL_NAME_KEY
                @levels << val
              end
            end
          end
        end
      end
      
      def set_counters!
        counts = [0] * (@levels.length+1)
        @frames.each do |frame|
          counts[frame.level] += 1
          key = @levels[frame.level]
          frame[key] = counts[frame.level]
          counts.fill(0, (frame.level+1)..@levels.length)
        end
      end
      
      def set_parents!
        parents = []
        @frames.reverse_each do |frame|
          parents[frame.level] = frame
          frame.parent = parents[frame.level-1] # This will be nil for empty slots.
        end
      end
      
      class Frame
        attr_accessor :level
        attr_accessor :parent
        def initialize(parser)
          @level = nil
          @parent = nil
          @data = Hash.new
          @parser = parser
        end
        
        def columns
          my_data = @data.dup
          return my_data if @parent.nil?
          parent_data = @parent.columns
          parent_data.each do |key, val|
            if my_data.has_key?(key)
              @parser.skip_column(key)
              # Append a string like "[Session]" or "[Block]" to the key name
              my_data["#{key}[#{@parser.levels[@level]}]"] = my_data[key]
              my_data["#{key}[#{@parser.levels[@parent.level]}]"] = val
            else
              my_data[key] = parent_data[key]
            end
          end
          return my_data
        end
        
        def method_missing(meth, *args)
          @data.send meth, *args
        end
      end
    end # Class LogFileParser
  end # Class Reader
end # Module Eprime