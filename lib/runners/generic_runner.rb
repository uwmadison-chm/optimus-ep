# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

#
# This class should handle argument processing, file I/O, and such.


require 'optimus'
require 'optimus_reader'
require 'tabfile_writer'
require 'transformers/timing_extractor'
require 'optparse'
require 'ostruct'

module Optimus
  module Runners
    class GenericRunner
      include ::Optimus::Transformers
      
      attr_accessor :out, :err
      def initialize(extractor_class, *args)
        @extractor_class = extractor_class
        # caller() returns an array of 'filename:line' -- the last element
        # should contain the name of the script that started this process
        @script_name = File.basename(caller.last.split(':').first)
        @out = STDOUT
        @err = STDERR
        @args = args
        @data = nil
        @timing_extractor = nil
      end
      
      def process!
        process_arguments(*@args)
        validate
        read_data
        extract_timings
        write_timings
      end
      
      def read_data
        data = Optimus::Data.new()
        @options.input_files.each do |infile|
          File.open(infile) do |f|
            data.merge!(Optimus::Reader.new(f).optimus_data)
          end
        end
        @data = data
      end
      
      def extract_timings
        @timing_extractor = @extractor_class.new(@data)
        template_code = ''
        File.open(@options.template_file) { |f| 
          template_code = f.read 
        }
        @timing_extractor.instance_eval(template_code)
      end
      
      def write_timings
        if @options.outfile
          @out = File.open(@options.outfile, 'w')
        end
        writer = TabfileWriter.new(
          @timing_extractor.extracted_data, @out, 
          {:column_labels => @options.column_labels})
        begin
          writer.write
        rescue Errno::EPIPE => e
          # This is OK
        ensure
          if @options.outfile
            @out.close
          end
        end
      end
      
      def validate
        if @options.help || @args.flatten.size == 0
          show_help! and raise Exception.new()
        end
        if @options.input_files.empty?
          raise ArgumentError.new("no input files given\n#{usage}")
        end
        if !@options.template_file
          raise ArgumentError.new("no template file given\n#{usage}")
        end
        if !File.readable?(@options.template_file)
          raise ArgumentError.new("can't read #{@options.template_file}\n#{usage}")
        end
        return true
      end
      
      def show_help!
        @err.puts @op.to_s
      end
      
      def usage
        "#{@op.banner.to_s} \n#{@script_name} --help for help"
      end
      
      private
      def process_arguments(*args)
        @options = OpenStruct.new(
          :help => false,
          :outfile => nil,
          :column_labels => true,
          :template_file => nil,
          :input_files => []
        )
        
        op = OptionParser.new() do |op| 
          op.banner = "Usage: extract_timings --template TEMPLATE_FILE [OPTIONS] INPUT_FILES"
          op.separator ''
        
          op.on('-t', '--template=TEMPLATE_FILE', String,
            'A template containing commands describing',
            'how to process these files'
          ) { |t| @options.template_file = t } 
          
          op.separator ''
          op.on('--[no-]column-labels',
            'Print column lablels in the first row.',
            'If not specified, do print labels.'
          ) { |l| @options.column_labels = l }

          op.separator ''
          op.on('-o', '--outfile=OUTFILE',
            "The name of the file to save to. If not",
            "given, print to standard output."
          ) { |o| @options.outfile = o }

          op.separator ''
          op.on_tail('-h', '--help',
            'Print this message.'
          ) { |h| @options.help = h }
        end
        @options.input_files = op.parse(*args) || []
        @op = op
      end
      
    end
  end
end