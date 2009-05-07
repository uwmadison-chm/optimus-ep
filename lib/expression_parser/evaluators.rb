# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# Functions that actually handle evaluating operands and such.

module Eprime
  module ParsedCalculator
    module Evaluators
      NaN = 0.0/0.0
      
      def all_num?(*args)
        args.all? {|v| v.kind_of? Numeric}
      end
      module_function :all_num?
      
      
      module Prefix
        Neg = lambda {|rval| 
          if rval.kind_of? Numeric 
            return -rval
          else
            return NaN
          end
        }
        
        OpTable = {
          :- => Neg
        }
      end # module Prefix

      module Binary
        Plus = lambda {|lval, rval|
          return lval+rval if Evaluators.all_num?(lval, rval)
          return NaN
        }
        
        Minus = lambda {|lval, rval|
          return lval-rval if Evaluators.all_num?(lval, rval)
          return NaN
        }
        
        Times = lambda {|lval, rval|
          return lval*rval if Evaluators.all_num?(lval, rval)
          return NaN
        }
        
        Div = lambda {|lval, rval|
          return NaN if not Evaluators.all_num?(lval, rval)
          return NaN if rval.to_f == 0.0
          return lval.to_f/rval.to_f
        }
        
        Mod = lambda {|lval, rval|
          return lval%rval if Evaluators.all_num?(lval, rval)
          return NaN
        }
        
        Concat = lambda {|lval, rval|
          return lval.to_s+rval.to_s
        }
        
        OpTable = {
          :+ => Plus,
          :- => Minus,
          :* => Times,
          :/ => Div,
          :% => Mod,
          :& => Concat
        }
      end
    end
  end
end