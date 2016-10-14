require 'simplecov'
SimpleCov.start

require 'rubygems'
gem 'mocha'
require 'test/unit'
require 'mocha/test_unit'
require './lib/membership_function/sigmoid'
include Mocha::API


class SigmoidTest < Test::Unit::TestCase

  def test_parameter_number

    assert_equal(
      2, UFuzzyConvert::MembershipFunction::Sigmoid::PARAMETER_NUMBER
    )
  end

  def test_invalid_parameters
    assert_raise_with_message(
      UFuzzyConvert::InputError,
      "Parameters must be numeric."
    ) do
      UFuzzyConvert::MembershipFunction::Sigmoid.new "1", 2
    end

    assert_raise_with_message(
      UFuzzyConvert::InputError,
      "Parameters must be numeric."
    ) do
      UFuzzyConvert::MembershipFunction::Sigmoid.new 1, "2"
    end

  end

  def test_evaluate
    function = UFuzzyConvert::MembershipFunction::Sigmoid.new 2, 4

    assert_in_delta(3.3535e-04, function.evaluate(0), 3.3535e-04 * 1e-4)
    assert_in_delta(1.7986e-02, function.evaluate(2), 1.7986e-02 * 1e-4)
    assert_in_delta(5.0000e-01, function.evaluate(4), 5.0000e-01 * 1e-4)
    assert_in_delta(9.8201e-01, function.evaluate(6), 9.8201e-01 * 1e-4)
    assert_in_delta(9.9966e-01, function.evaluate(8), 9.9966e-01 * 1e-4)
    assert_in_delta(9.9999e-01, function.evaluate(10), 9.9999e-01 * 1e-4)
  end

end
