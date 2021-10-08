# frozen_string_literal: true

require 'spec_helper'

describe 'pam_tools::install_published' do
  # Include the BoltSpec library functions
  include BoltSpec::Plans

  include_context('with_tmpdir')

  let(:license_file) { "#{tmpdir}/license.yaml" }
  let(:targets) { ['spec-host'] }
  let(:plaintext_password) { 'puppet' }
  let(:password) do
    Puppet::Pops::Types::PSensitiveType::Sensitive.new(plaintext_password)
  end
  let(:params) do
    {
      'targets'              => targets,
      'license_file'         => license_file,
      'password'             => plaintext_password,
      'kots_install_options' => '--test-flag',
      'pam_variant'          => 'test-variant',
    }
  end

  # The bolt-spec matchers aren't composable; I can't use include or
  # regex matches on parameter checks, so I'm stuck with equating the
  # generated strings.
  def generate_connect_config(hostname, password, memory)
    mem_unit = memory * 1024 / 18
    <<~CONFIG
      ---
      apiVersion: 'kots.io/v1beta1'
      kind: 'ConfigValues'
      metadata:
        name: 'connect'
      spec:
        values:
          hostname:
            value: '#{hostname}'
          analytics:
            value: '0'
          accept_eula:
            value: 'has_accepted_eula'
          root_email:
            value: 'noreply@puppet.com'
          root_password:
            value: #{password}
          connect_postgres_console_memory:
            value: '#{mem_unit}'
          connect_postgres_puppetdb_memory:
            value: '#{mem_unit * 2}'
          connect_postgres_orchestrator_memory:
            value: '#{mem_unit}'
          connect_console_memory:
            value: '#{mem_unit * 3}'
          connect_orch_memory:
            value: '#{mem_unit * 3}'
          connect_bolt_memory:
            value: '#{mem_unit * 1}'
          connect_puppetdb_memory:
            value: '#{mem_unit * 3}'
          connect_puppetserver_memory:
            value: '#{mem_unit * 4}'
          # These are testing overrides to allow scheduling on a 4cpu test host.
          pe_console_cpu_request:
            value: '100m'
          pe_orchestrator_cpu_request:
            value: '100m'
          pe_puppetdb_cpu_request:
            value: '100m'
          pe_puppetserver_cpu_request:
            value: '100m'
      # vim: ft=yaml
    CONFIG
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
        'license_content'      => license('connect'),
        'config_content'       => generate_connect_config('spec-host', plaintext_password, 8),
        'password'             => password,
        'airgap_bundle'        => nil,
        'hostname'             => 'spec-host',
        'kots_namespace'       => 'default',
        'kots_wait_duration'   => '5m',
        'kots_install_options' => '--test-flag',
        'pam_variant'          => 'test-variant',
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
        'password'      => plaintext_password,
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
