require 'spec_helper'

describe 'pam_tools::get_kots_app' do
  it 'identifies cd4pe' do
    is_expected.to run.with_params(license('cd4pe')).and_return('cd4pe')
  end

  it 'identifies connect' do
    is_expected.to run.with_params(license('connect')).and_return('connect')
  end

  it 'identifies comply' do
    is_expected.to run.with_params(license('comply')).and_return('comply')
  end
end
