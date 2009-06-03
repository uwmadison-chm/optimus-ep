# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# Functions that actually handle evaluating operands and such.

module Optimus
  module ParsedCalculator
    module Evaluators
      NaN = 0.0/0.0
      
      class ArgList
        include Enumerable
        attr_accessor :args
        def initialize(*args)
          @args = args
        end
        
        def each(&block)
          @args.each(&block)
        end
        
        def all_num?
          @args.all? {|v| v.kind_of? Numeric }
        end
        
        def cast_for_comparison
          @args.map {|v| floatify(v) }
        end
        
        def bool_cast
          @args.map {|v| v.to_s.strip == '' ? false : v }
        end
        
        private
        def floatify(arg)
          return arg.to_f if arg.kind_of? Numeric
          return arg.to_s.to_f if arg.to_s =~ /^-?\d+\.?\d*$/ 
          return arg
        end        
      end
      
      module Prefix
        Neg = lambda {|rval| 
          if rval.kind_of? Numeric 
            return -rval
          else
            return NaN
          end
        }
        
        Not = lambda {|rval|
          args = ArgList.new(rval)
          cr = args.bool_cast[0]
          return (not(cr))
        }
        
        OpTable = {
          :- => Neg,
          :not => Not
        }
      end # module Prefix

      # Actual functions to evaluate binary expressions such as
      # 1+1 and 5%3.
      # Here is where we get to say what our operators actually do!
      module Binary
        Plus = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          return lval+rval if args.all_num?
          return NaN
        }
        
        Minus = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          return lval-rval if args.all_num?
          return NaN
        }
        
        Times = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          return lval*rval if args.all_num?
          return NaN
        }
        
        Div = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          return NaN if rval.to_f == 0.0
          return lval.to_f/rval.to_f
        }
        
        Mod = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          return lval%rval if args.all_num?
          return NaN
        }
        
        Concat = lambda {|lval, rval|
          return lval.to_s+rval.to_s
        }
        
        And = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.bool_cast
          return (cl and cr)
        }
        
        Or = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.bool_cast
          return (cl or cr)
        }
        
        Equals = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.cast_for_comparison
          return cl == cr
        }
        
        NotEquals = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.cast_for_comparison
          return cl != cr
        }
        
        GreaterThan = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.cast_for_comparison
          begin
            return cl > cr
          rescue ArgumentError => e
            return false
          end
        }
        
        LessThan = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.cast_for_comparison
          begin
            return cl < cr
          rescue ArgumentError => e
            return false
          end
        }
        
        GreaterThanEquals = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.cast_for_comparison
          begin
            return cl >= cr
          rescue ArgumentError => e
            return false
          end
        }
        
        LessThanEquals = lambda {|lval, rval|
          args = ArgList.new(lval, rval)
          cl, cr = args.cast_for_comparison
          begin
            return cl <= cr
          rescue ArgumentError => e
            return false
          end
        }

        OpTable = {
          :+ => Plus,
          :- => Minus,
          :* => Times,
          :/ => Div,
          :% => Mod,
          :& => Concat,
          :and => And,
          :or => Or,
          '='.to_sym => Equals,
          '!='.to_sym => NotEquals,
          :> => GreaterThan,
          :< => LessThan,
          :>= => GreaterThanEquals,
          :<= => LessThanEquals
        }
      end
    end
  end
end