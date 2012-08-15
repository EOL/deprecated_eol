require 'spec/runner/formatter/base_text_formatter'
class ExpectationFormatter < RSpec::Runner::Formatter::BaseTextFormatter
  def print_eol_expectations
    if $EOL_CURRENT_EXPECTATIONS && ! $EOL_CURRENT_EXPECTATIONS.empty?
       output.puts(yellow("  ...#{$EOL_CURRENT_EXPECTATIONS.join(",\n  ...")}."))
       $EOL_CURRENT_EXPECTATIONS = []
    end
  end

  def show_and_reset_time(msg = '')
    output.puts(yellow(msg + (Time.now() - $THIS_SPEC_START_TIME).round(2).to_s + " seconds")) if $THIS_SPEC_START_TIME
    $THIS_SPEC_START_TIME = Time.now()
  end

  def example_group_started(example_group)
    super
    output.puts
    output.puts example_group.description
    output.flush
  end

  def close
    if $EOL_EXPECTATION_COUNT && $EOL_EXPECTATION_COUNT > 0
      output.puts(yellow("#{$EOL_EXPECTATION_COUNT} expectations."))
    end
    show_and_reset_time("Final example group took ")
  end

  def example_group_started(example_group)
    super
    show_and_reset_time
    output.puts
    output.puts example_group.description
    output.flush
  end

  def example_failed(example, counter, failure)
    output.puts(red("F #{example.description} (FAILED - #{counter})"))
    print_eol_expectations
    output.flush
  end

  def example_passed(example)
    output.puts green(". #{example.description}")
    print_eol_expectations
    output.flush
  end

  def example_pending(example, message, deprecated_pending_location=nil)
    super
    output.puts yellow("* #{example.description} (PENDING: #{message})")
    output.flush
  end

end
