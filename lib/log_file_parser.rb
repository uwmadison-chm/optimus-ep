# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  class Reader
    
    # Reads and parses E-Prime log files (the ones that start with 
    # *** Header Start ***) and transforms them into an Eprime::Data structure
    
    
    class LogfileParser
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
        @found_cols = ColumnList.new()
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
          raise e unless @force
        end
    
        @columns ||= @found_cols.names
        data = Eprime::Data.new(@columns)
        self.leaf_frames.each do |frame|
          row = data.add_row
          @found_cols.names_with_cols.each do |pair|
            name, col = *pair
            val = frame.get(col)
            row[name] = val
          end
        end
        return data
      end
      
      def leaf_frames
        return frames.find_all { |frame| frame.leaf? }
      end
      
      # Define this as a column we *should not* include in out output.
      def skip_column(col_name)
        @skip_columns[col_name] = true
      end
      
      def self.can_parse?(lines)
        lines[0].include?('*** Header Start ***')
      end
      
      private
      # iterate over each line, strip it, look for *** LogFrame Start *** and
      # *** LogFrame End *** -- the content between those goes into a frame array.
      # If we start a frame but don't end it, raise a DamagedFileError
      def frameify(file)
        in_frame = false
        frames = []
        # This 
        frame = Frame.new(self)
        frame.level = 0
        file.each_line do |line|
          # TODO? Refactor this out into its own private function
          l_s = line.strip
          key, val = l_s.split(/: */, 2) # There isn't always a space, and values can contain colons
          
          if !in_frame
            if key == LEVEL_KEY
              frame.level = val.to_i
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
              @found_cols.store(Column.new(key, frame.level))
            end
          end
        end
        if in_frame
          raise DamagedFileError.new(
            "Last frame never closed in #{file.path}"
          ) 
          end
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
              @found_cols.levels = @levels
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
          @found_cols.store(Column.new(key, frame.level))
          frame[key] = counts[frame.level]
          counts.fill(0, (frame.level+1)..@levels.length)
        end
      end
      
      def set_parents!
        parents = []
        @frames.reverse_each do |frame|
          child = parents[frame.level-1]
          
          parents[frame.level] = frame
          frame.parent = parents[frame.level-1] # This will be nil for empty slots.
        end
      end
      
      class Frame
        include Enumerable
        
        attr_accessor :level
        attr_accessor :parent
        attr_accessor :children
        def initialize(parser)
          @level = nil
          @parent = nil
          @children = []
          @data = Hash.new
          @parser = parser
        end
        
        def parent=(new_parent)
          if @parent
            if new_parent != @parent
              @parent.children.delete(self)
            end
          end
          @parent = new_parent
          @parent.children << self if @parent
        end
        
        def leaf?
          @children.empty?
        end
        
        # Methods to make this behave hashlike. Don't just delegate to 
        # the @data hash; that's less clear.
        def [](key)
          return @data[Column.new(key, @level).to_s]
        end
        
        def []=(key, val)
          @data[Column.new(key, @level).to_s] = val
        end
        
        def keys
          @data.keys
        end
        
        def each
          @data.each do |k, v|
            yield k, v
          end
        end
        
        def get(col)
          # If the value is supposed to be at our level, return it (nil is OK)
          return @data[col.to_s] if col.level == @level
          # If it could be in our parent, return that.
          return @parent.get(col) if (@parent && col.level < @level)
          # If that's not an option,
          return nil
        end
      end
      
      class ColumnList
        attr_accessor :levels
        def initialize(levels = [], cols = [])
          @levels = levels
          @cols = cols
          @name_uses = Hash.new(0)
        end
        
        def store(col)
          if (col.level >= @levels.length  or col.level < 1)
            raise IndexError.new(
              "Level #{col.level} must be between 1 and #{@levels.length-1}")
          end
          if not @cols.include?(col)
            @cols << col
            @name_uses[col.name] += 1
          end
        end
        
        def names
          return self.names_with_cols.map { |c| 
            c[0]
          }
        end
        
        def names_with_cols
          ncm = sorted_cols.map {|c| [
              (@name_uses[c.name]==1) ? 
                c.name : "#{c.name}[#{@levels[c.level]}]",
              c ]}
          return ncm
        end
        
        def sorted_cols
          cwi = []
          @cols.each_with_index do |col, i|
            cwi << [col, i]
          end
          return cwi.sort_by {|elem| [elem[0].level, elem[1]]}.map {|elem| 
            elem[0]
          }
        end
        

      end

      class Column
        attr_accessor :name, :level
        def initialize(name, level)
          @name = name
          @level = level
        end
        
        def ==(c)
          @name == c.name and @level == c.level
        end
        
        def hash
          return self.to_s.hash
        end
        
        def to_s
          "#{@name}[#{@level}]"
        end
      end
    end # Class LogfileParser
  end # Class Reader
end # Module Eprime