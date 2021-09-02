require 'spec_helper'

describe 'pam_tools::check_for_file' do
  it 'verifies file exists' do
    is_expected.to run.with_params('test', '/dev/null').and_return('/dev/null')
  end

  it 'raises if not found' do
    is_expected.to(
      run.with_params('test', '/doesnotexist')
        .and_raise_error(%r{test /doesnotexist could not be found})
    )
  end

  it 'raises if no path parameter is given' do
    is_expected.to(
      run.with_params('test', nil)
        .and_raise_error(%r{No path to 'test' file given.})
    )
  end

  it 'returns undef if no path is given' do
    is_expected.to run.with_params('test', nil, false).and_return(nil)
  end
end
