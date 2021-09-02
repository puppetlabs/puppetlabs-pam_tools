require 'spec_helper'

describe 'pam_tools::get_kots_slug' do
  let(:good_license) { license('cd4pe') }
  let(:errmsg) { %r{Unable to locate.*appSlug.*in.*bad-license}m }

  it 'returns the app slug value' do
    is_expected.to(
      run.with_params(good_license).and_return('cd4pe')
    )
  end

  it 'raises an informative error if license is not a Hash' do
    is_expected.to(
      run.with_params('bad-license')
        .and_raise_error(%r{Unable to locate.*appSlug.*in.*bad-license}m)
    )
  end

  it 'raises if appSlug is not present' do
    license = <<~EOS
      foo: bar
      biff: baz
    EOS
    is_expected.to(
      run.with_params(license)
        .and_raise_error(%r{Unable to locate.*appSlug.*in.*#{license}}m)
    )
  end
end
