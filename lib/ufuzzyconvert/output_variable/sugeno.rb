require 'bigdecimal'

module UFuzzyConvert

  require_relative '../output_variable'
  require_relative '../fixed_point'

  class SugenoVariable < OutputVariable

    require_relative '../membership_function'
    require_relative '../rule/sugeno'

    CFS_TYPE = 1

    ##
    # Creates a Sugeno output variable from FIS data.
    #
    # @param [Hash] output_data
    #   A sugeno variable section parsed from a FIS file.
    # @param [Hash] system_data
    #   Unused.
    # @return [Sugeno]
    # @raise [InputError]
    #   When range_min or range_max have invalid values.
    #
    def self.from_fis_data(output_data, system_data)
      # May raise InputError.
      range_min, range_max = range_from_fis_data output_data

      return SugenoVariable.new(range_min, range_max)
    end

    def membership_functions=(membership_functions)

      membership_functions.each do |membership_function|
        if not membership_function.class == MembershipFunction::Linear
           not membership_function.class == MembershipFunction::Constant
          raise InputError.new, "Sugeno variables can only use linear or "\
                                "constant membership functions."
        end
      end

      super
    end

    def load_rules_from_fis_data(
      inputs, and_operator, or_operator, rules_data
    )
      @rules = rules_from_fis_data(
        SugenoRule,
        inputs,
        and_operator,
        or_operator,
        rules_data
      )
    end

    private def fit_independent_terms(range_min, range_max, scale)
      minimum = Float::INFINITY
      maximum = -Float::INFINITY
      rules.each do |rule|
        rule_min, rule_max = rule.fit_independent_term(
          range_min, range_max, scale
        )
        if rule_min < minimum then minimum = rule_min end
        if rule_max > maximum then maximum = rule_max end
      end

      return [minimum, maximum]
    end

    private def output_limits
      # Calculate the minimum and maximum values for each rule.
      ranges = rules.map{ |rule| rule.output_limits }

      transposed = ranges.transpose

      # Calculate the minimum and maximum values for this output.
      return transposed[0].min, transposed[1].max
    end

    ##
    # Returns a suggested range for the output variable, such as all the
    # Sugeno's coefficients can be represented in fixed point format.
    #
    # @return [Array<Numeric>] Returns an(output_min, output_max) pair.
    #
    def suggested_range
      # Calculate the minimum and maximum values for this output.
      output_min, output_max = output_limits

      # Using output_min and output_max as range, implies that the normalized
      # output value will be in [0, 1]. The fixed point representation allows
      # numbers in the range [-2, 2). This means that using output_min and
      # output_max two bits of the fixed point representation are being wasted.
      # To take adventage of these two bits, the output should belong to [-2, 2)
      range_min, range_max = FixedPoint.optimal_range(output_min, output_max)

      # Calculate the coefficient overflow for each rule if these new limits are
      # used.
      coefficient_overflows = rules.map{ |rule|
        rule.coefficient_overflow range_min, range_max
      }

      # Find the greatest overflow
      maximum = coefficient_overflows.max
      minimum = coefficient_overflows.min
      overflow = minimum.abs > maximum.abs ? minimum : maximum

      # Fix the range to fit the independent term scaling the range to fit all
      # the other coefficients.
      suggested_min, suggested_max = fit_independent_terms(
        range_min, range_max, overflow.abs > 1 ? overflow.abs : 1
      )

      rounding = (suggested_max - suggested_min) * 0.00001
      return [
        BigDecimal.new(suggested_min - rounding, 5).to_f,
        BigDecimal.new(suggested_max + rounding, 5).to_f
      ]
    end

    ##
    # Converts an {OutputVariable} into a CFS array.
    #
    # @param [Hash<Symbol>] options
    #   Unused, but preserved to keep compatibility with other output
    #   variable types.
    # @return [Array<Integer>]
    #   Returns the output varaible converted to CFS format.
    # @raise  [InputError]
    #  When the FIS data contains incomplete or erroneous information.
    #
    def to_cfs(options)

      cfs_data = Array.new

      cfs_data.push CFS_TYPE
      cfs_data.push @rules.size

      rules.each.with_index(1) do |rule, rule_index|
        begin
          cfs_data.push(*rule.to_cfs)
        rescue FixedPointError
          raise $!,
                "Rule #{rule_index} that affects Output #{index}: #{$!}\n"\
                "The suggested range for Output #{index} is "\
                "#{suggested_range}.",
                $!.backtrace
        rescue UFuzzyError
          raise $!,
                "Rule #{rule_index} that affects Output #{index}: #{$!}",
                $!.backtrace
        end
      end
      return cfs_data
    end
  end
end
