# frozen_string_literal: true

require 'spec_helper'

describe 'pam_tools::install_published' do
  # Include the BoltSpec library functions
  include BoltSpec::Plans

  include_context('with_tmpdir')

  let(:license_file) { "#{tmpdir}/license.yaml" }
  let(:targets) { ['spec-host'] }
  let(:password) do
    Puppet::Pops::Types::PSensitiveType::Sensitive.new('puppet')
  end
  let(:params) do
    {
      'targets'      => targets,
      'license_file' => license_file,
      'password'     => 'puppet',
    }
  end

  before(:each) do
    File.write(license_file, license('connect'))
  end

  it 'runs' do
    expect_task('pam_tools::get_kots_app_status')
      .with_targets(targets)
      .with_params(
        'kots_slug'      => 'cd4pe',
        'kots_namespace' => 'default',
        'verbose'        => false,
      )
      .always_return({ '_output' => 'not-installed' })
    expect_task('pam_tools::kots_install')
      .with_targets(targets)
      .always_return({ 'appname' => 'connect', 'kots_slug' => 'cd4pe' })
      .with_params(
        'license_content' => license('connect'),
        'password' => password,
        'airgap_bundle' => nil,
        'hostname' => 'spec-host',
        'kots_namespace' => 'default',
        'kots_wait_duration' => '5m',
        'kots_install_options' => nil,
      )
    expect_out_message.with_params('Installed connect on spec-host')
    expect_task('pam_tools::wait_for_app')
      .with_targets(targets)
      .with_params(
        'kots_slug'      => 'cd4pe',
        'app_hostname'   => 'spec-host',
        'kots_namespace' => 'default',
        'app_timeout'    => '600s',
        'sts_timeout'    => '300s',
        'http_timeout'   => '60s',
      )
    result = run_plan('pam_tools::install_published', params)

    expect(result.ok?).to eq(true)
    expect(result.value['kots_slug']).to eq('cd4pe')
    expect(result.value['kots_app']).to eq('connect')
  end

  it 'skips installing if already installed' do
    expect_task('pam_tools::get_kots_app_status').always_return({ '_output' => 'ready' })
    expect_task('pam_tools::kots_install').not_be_called
    expect_out_message.with_params('All targets already installed.')
    expect_task('pam_tools::wait_for_app')

    result = run_plan('pam_tools::install_published', params)
    expect(result.ok?).to eq(true)
  end

  it 'runs without waiting' do
    params['wait_for_app'] = false

    expect_task('pam_tools::get_kots_app_status').always_return({ '_output' => 'not-installed' })
    expect_task('pam_tools::kots_install')
    expect_task('pam_tools::wait_for_app').not_be_called

    result = run_plan('pam_tools::install_published', params)
    expect(result.ok?).to eq(true)
  end

  context 'with an airgap bundle' do
    let(:airgap_bundle) { "#{tmpdir}/app.bundle" }
    let(:params) do
      {
        'targets'       => targets,
        'license_file'  => license_file,
        'airgap_bundle' => airgap_bundle,
        'password'      => 'puppet',
      }
    end

    before(:each) do
      File.write(airgap_bundle, 'nonsense')
    end

    it 'runs without waiting' do
      params['wait_for_app'] = false

      expect_task('pam_tools::get_kots_app_status').always_return({ '_output' => 'not-installed' })
      expect_upload(airgap_bundle).with_destination('/tmp/connect.airgap').with_targets(targets)
      expect_task('pam_tools::kots_install')
      expect_task('pam_tools::wait_for_app').not_be_called

      result = run_plan('pam_tools::install_published', params)
      expect(result.ok?).to eq(true)
    end
  end
end
