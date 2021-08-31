# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/kots_install.rb'
require 'yaml'

describe 'kurl_test::kots_install' do
  let(:task) { KotsInstall.new }

  context '#get_slug' do
    it 'extracts the slug from the license' do
      expect(task.get_slug(license_hash('cd4pe'))).to eq('cd4pe')
    end

    it 'returns nil if given an empty hash' do
      expect(task.get_slug({})).to be_nil
    end

    it 'raises if not given a hash' do
      expect { task.get_slug(nil) }.to raise_error(ArgumentError, %r{expected a license hash}i)
    end
  end

  context '#get_appname' do
    it 'gets cd4pe appname from license' do
      expect(task.get_appname(license_hash('cd4pe'))).to eq('cd4pe')
    end

    it 'gets connect appname from license' do
      expect(task.get_appname(license_hash('connect'))).to eq('connect')
    end

    it 'gets comply appname from license' do
      expect(task.get_appname(license_hash('comply'))).to eq('comply')
    end
  end

  it 'generates #base_config' do
    expect(task.base_config('connect', 'foo.rspec')).to include(
      'apiVersion' => 'kots.io/v1beta1',
      'metadata' => { 'name' => 'connect' },
      'spec' => {
        'values' => include(
          'hostname' => { 'value' => 'foo.rspec' }
        )
      },
    )
  end

  it 'generates #root_account_config' do
    expect(task.root_account_config('connect', 'puppet')).to eq(
      {
        'root_email'    => { 'value' => 'noreply@puppet.com' },
        'root_password' => { 'value' => 'puppet' },
      }
    )
  end

  it 'generates #constraints_config' do
    expect(task.constraints_config('connect')).to include(
      'connect_postgres_console_memory' => { 'value' => '256' }
    )
  end

  context '#generate_config' do
    it 'generates' do
      expect(task.generate_config(license_hash('connect'), 'foo.rspec', 'puppet')).to(
        include(
          'apiVersion' => 'kots.io/v1beta1',
          'metadata' => { 'name' => 'connect' },
          'spec' => {
            'values' => include(
              'hostname'            => { 'value' => 'foo.rspec' },
              'root_password'       => { 'value' => 'puppet' },
              'connect_bolt_memory' => { 'value' => '256' },
            )
          },
        )
      )
    end
  end

  context '#task' do
    include_context('with_tmpdir')

    it 'installs' do
      args = {
        license_content: license('connect'),
        password: 'puppet',
        hostname: 'foo.rspec',
        kots_namespace: 'default',
        kots_wait_duration: '5m',
      }

      expect(Dir).to receive(:mktmpdir).with('kots-install').and_return(tmpdir)
      expect(task).to receive(:run_command).with(
        [
          'kubectl-kots',
          'install',
          'puppet-application-manager/stable',
          '--namespace=default',
          '--shared-password=puppet',
          '--port-forward=false',
          "--license-file=#{tmpdir}/license.yaml",
          "--config-values=#{tmpdir}/config.yaml",
          '--wait-duration=5m',
        ]
      ).and_return('installed')

      expect(task.task(args)).to include(
        appname: 'connect',
        kots_slug: 'cd4pe',
      )
    end
  end

  context '#task with optional args' do
    include_context('with_tmpdir')

    it 'installs' do
      config_content = { 'apiVersion' => 'kots.io/v1beta1', 'kind' => 'ConfigValues' }
      args = {
        license_content: license('connect'),
        password: 'puppet',
        hostname: 'foo.rspec',
        kots_namespace: 'default',
        kots_wait_duration: '5m',
        config_content: config_content.to_yaml,
        kots_install_options: '',
        airgap_bundle: './bundle.airgap',
      }

      expect(Dir).to receive(:mktmpdir).with('kots-install').and_return(tmpdir)
      expect(task).to receive(:run_command).with(
        [
          'kubectl-kots',
          'install',
          'puppet-application-manager/stable',
          '--namespace=default',
          '--shared-password=puppet',
          '--port-forward=false',
          "--license-file=#{tmpdir}/license.yaml",
          "--config-values=#{tmpdir}/config.yaml",
          '--wait-duration=5m',
          '--airgap-bundle=./bundle.airgap',
        ]
      ).and_return('installed')

      expect(task.task(args)).to include(
        appname: 'connect',
        kots_slug: 'cd4pe',
      )

      config = YAML.safe_load(File.read(File.join(tmpdir, 'config.yaml')))
      expect(config).to eq(config_content)
    end
  end

  context '.run' do
    it 'installs' do
      json_input = '{"foo":"bar"}'
      params_hash = { foo: 'bar' }
      output_hash = { thing: 'done' }

      runner = instance_double('PAMTaskHelper')
      expect($stdin).to receive(:read).and_return(json_input)
      expect(runner).to receive(:task).with(params_hash).and_return(output_hash)
      expect(KotsInstall).to receive(:new).and_return(runner)

      expect { KotsInstall.run }.to(
        output(output_hash.to_json.to_s).to_stdout
      )
    end
  end
end
