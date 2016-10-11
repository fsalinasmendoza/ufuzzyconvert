module UFuzzyConvert

  require_relative 'exception'
  require_relative 'membership_function'

  class InputVariable

    #----------------------------[constants]-----------------------------------#


    #----------------------------[public class methods]------------------------#

    ##
    # Creates an {InputVariable} object from FIS data.
    #
    # @param [Hash] input_data
    #   The parsed input section of a FIS file.
    # @option input_data [Integer] :index
    #   Index of the input variable.
    # @option input_data [Hash] :parameters
    #   All the parameters of the input section, i.e. Range.
    # @option input_data [Array<Hash>] :membership
    #   An array with all the membership function data for this input variable.
    # @return [InputVariable]
    #   A new {InputVariable} object.
    # @raise [FeatureError]
    #  When a feature present in the FIS data is not supported.
    # @raise  [InputError]
    #  When the FIS data contains incomplete or erroneous information.
    #
    def self.from_fis_data(input_data)

      begin
        range_min, range_max = range_from_fis_data input_data
        membership_functions = membership_functions_from_fis_data input_data

        return InputVariable.new range_min, range_max, membership_functions
      rescue UFuzzyError
        raise $!, "Input #{input_data[:index]}: #{$!}", $!.backtrace
      end
    end

    #----------------------------[initialization]------------------------------#

    ##
    # Creates an {InputVariable} object.
    #
    # @param [Numeric] range_min
    #   The minimum value that the variable is able to take.
    # @param [Numeric] range_max
    #   The maximum value that the variable is able to take.
    # @param [Array<InputVariable>] membership_functions
    #   Membership functions for this variable.
    # @raise [InputError]
    #   When range_min or range_max have invalid values.
    #
    def initialize(range_min, range_max, membership_functions)
      if not range_min.is_a? Numeric
        raise InputError.new, "Range lower bound must be a number."
      end
      if not range_max.is_a? Numeric
        raise InputError.new, "Range upper bound must be a number."
      end
      if range_max <= range_min
        raise InputError.new, "Range bounds are swapped."
      end

      @range_min = range_min
      @range_max = range_max
      @membership_functions = membership_functions
    end

    #----------------------------[public methods]------------------------------#

    ##
    # Converts an {InputVariable} into a CFS array.
    #
    # @param [Hash<Symbol>] options
    # @option options [Integer] :dsteps
    #   Base 2 logarithm of the number of defuzzification steps to be performed.
    # @option options [Integer] :tsize
    #   Base 2 logarithm of the number of entries in a tabulated membership
    #   function.
    # @return [Array<Integer>]
    #   Returns the input varaible converted to CFS format.
    # @raise [FeatureError]
    #  When a feature present in the FIS data is not supported.
    # @raise  [InputError]
    #  When the FIS data contains incomplete or erroneous information.
    #
    def to_cfs(options)
      cfs_data = Array.new

      cfs_data.push(@membership_functions.length)
      cfs_data.push(0)

      @membership_functions.each do |membership_function|
        cfs_data.push(
          *membership_function.to_cfs(@range_min, @range_max, options)
        )
      end

      return cfs_data
    end

    #----------------------------[private class methods]-----------------------#

    class << self

      def range_from_fis_data(input_data)

        if not input_data.key? :parameters
          raise InputError.new, "No parameters found. Range is required."
        end
        param_data = input_data[:parameters]

        if not param_data.key? :Range
          raise InputError.new, "Range not defined."
        end

        range = param_data[:Range]
        if range.length != 2
          raise InputError.new, "Range matrix must have two elements."
        end
        return range[0], range[1]
      end

      def membership_functions_from_fis_data(input_data)
        membership_functions = Array.new

        membership_data_list = input_data[:membership]
        unless membership_data_list.nil?
          membership_data_list.each do |index, membership_data|
            membership_functions.push(
              MembershipFunction.from_fis_data membership_data
            )
          end
        end

        return membership_functions
      end

    end

    #----------------------------[private methods]-----------------------------#

  end

end
