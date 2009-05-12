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
      
      def cast_for_comparison(*args)
        aout = args.dup
        # If any argument is numeric, cast everything to a number.
        # Otherwise, don't touch.
        if args.any? {|v| v.kind_of? Numeric }
          aout = args.map {|v| floatify(v) }
        end
        return aout
      end
      module_function :cast_for_comparison
      
      def floatify(arg)
        return arg.to_f if arg.kind_of? Numeric
        return arg.to_s.to_f if arg.to_s =~ /^-?\d+\.?\d*$/ 
        return arg
      end
      
      def bool_cast(*args)
        args.map {|v| v.to_s.strip == '' ? false : v}
      end
      module_function :bool_cast
      
      module Prefix
        Neg = lambda {|rval| 
          if rval.kind_of? Numeric 
            return -rval
          else
            return NaN
          end
        }
        
        Not = lambda {|rval|
          cr = Evaluators.bool_cast(rval)[0]
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
        
        And = lambda {|lval, rval|
          cl, cr = Evaluators.bool_cast(lval, rval)
          return (cl and cr)
        }
        
        Or = lambda {|lval, rval|
          cl, cr = Evaluators.bool_cast(lval, rval)
          return (cl or cr)
        }
        
        Equals = lambda {|lval, rval|
          cl, cr = Evaluators.cast_for_comparison(lval, rval)
          return cl == cr
        }
        
        NotEquals = lambda {|lval, rval|
          cl, cr = Evaluators.cast_for_comparison(lval, rval)
          return cl != cr
        }
        
        GreaterThan = lambda {|lval, rval|
          cl, cr =  Evaluators.cast_for_comparison(lval, rval)
          begin
            return cl > cr
          rescue ArgumentError => e
            return false
          end
        }
        
        LessThan = lambda {|lval, rval|
          cl, cr =  Evaluators.cast_for_comparison(lval, rval)
          begin
            return cl < cr
          rescue ArgumentError => e
            return false
          end
        }
        
        GreaterThanEquals = lambda {|lval, rval|
          cl, cr =  Evaluators.cast_for_comparison(lval, rval)
          begin
            return cl >= cr
          rescue ArgumentError => e
            return false
          end
        }
        
        LessThanEquals = lambda {|lval, rval|
          cl, cr =  Evaluators.cast_for_comparison(lval, rval)
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