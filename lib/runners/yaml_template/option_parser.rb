# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# OptionParser for the yaml_template_runner


require 'optimus'
require 'optparse'

module Optimus
  module Runners
    module YamlTemplate
      class OptimusOptionParser
        attr_reader :errors
        def initialize
          @errors = []
        end
      end
      
      class OptionParserFactory
        class << self
          def build
            
          end
        end
      end
    end
  end
end
