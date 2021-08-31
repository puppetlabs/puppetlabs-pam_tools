# frozen_string_literal: true

RSpec.shared_context('with_tmpdir') do
  let(:tmpdir) { @tmpdir }

  around(:each) do |example|
    Dir.mktmpdir('rspec-kurl_test') do |t|
      @tmpdir = t
      example.run
    end
  end
end
