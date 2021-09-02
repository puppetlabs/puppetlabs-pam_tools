require 'spec_helper'

describe 'pam_tools::generate_random_password' do
  it { is_expected.to run.with_params(16).and_return(%r{^\w{16}$}) }
end
