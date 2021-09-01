# frozen_string_literal: true

# Cribbed from Puppet spec/lib/puppet_spec/matchers.rb
# But this version supports block expectations.
RSpec::Matchers.define :exit_with do |expected|
  actual = nil
  match do |block|
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual && (actual == expected)
  end

  supports_block_expectations

  failure_message do |_block|
    "expected exit with code #{expected} but " +
      (actual.nil? ? ' exit was not called' : "we exited with #{actual} instead")
  end

  failure_message_when_negated do |_block|
    "expected that exit would not be called with #{expected}"
  end

  description do
    "expect exit with #{expected}"
  end
end
