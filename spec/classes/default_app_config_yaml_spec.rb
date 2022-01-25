# frozen_string_literal: true

require 'spec_helper'

# Validate the default Replicated app config.yaml template.
# This test class is in spec/manifests.
describe 'pam_tools::test_default_app_config_template' do
  def get_values_yaml(catalog)
    r = catalog.resource('Notify[template-output]')
    YAML.safe_load(r['message'])
  end

  let(:template_parameters) do
    {
      'kots_app' => 'test-app',
      'hostname' => 'test.rspec',
    }
  end
  let(:params) do
    {
      template_parameters: template_parameters
    }
  end
  let(:yaml) { get_values_yaml(catalogue) }

  it 'compiles the template' do
    is_expected.to compile
  end

  it 'produces a default' do
    expect(yaml).to eq(
      {
        'apiVersion' => 'kots.io/v1beta1',
        'kind'       => 'ConfigValues',
        'metadata'   => {
          'name' => 'test-app'
        },
        'spec' => {
          'values' => {
            'accept_eula' => { 'value' => 'has_accepted_eula' },
            'analytics' => { 'value' => '0' },
            'hostname' => { 'value' => 'test.rspec' },
          },
        },
      }
    )
  end

  it 'produces a cd4pe config' do
    template_parameters['kots_app'] = 'cd4pe'
    template_parameters['password'] = 'password'
    expect(yaml).to eq(
      {
        'apiVersion' => 'kots.io/v1beta1',
        'kind' => 'ConfigValues',
        'metadata' => {
          'name' => 'cd4pe'
        },
        'spec' =>  {
          'values' => {
            'hostname' => { 'value' => 'test.rspec' },
            'analytics' => { 'value' => '0' },
            'accept_eula' => { 'value' => 'has_accepted_eula' },
            'root_email' => { 'value' => 'noreply@puppet.com' },
            'root_password' => { 'value' => 'password' },
          }
        }
      }
    )
  end

  it 'produces a comply config' do
    template_parameters['kots_app'] = 'comply'
    expect(yaml).to eq(
      {
        'apiVersion' => 'kots.io/v1beta1',
        'kind' => 'ConfigValues',
        'metadata' => {
          'name' => 'comply'
        },
        'spec' =>  {
          'values' => {
            'hostname' => { 'value' => 'test.rspec' },
            'analytics' => { 'value' => '0' },
            'accept_eula' => { 'value' => 'has_accepted_eula' },
          }
        }
      }
    )
  end

  it 'produces a comply config for miniscule cpu' do
    template_parameters['kots_app'] = 'comply'
    template_parameters['allocated_cpu'] = 4
    expect(yaml).to eq(
      {
        'apiVersion' => 'kots.io/v1beta1',
        'kind' => 'ConfigValues',
        'metadata' => {
          'name' => 'comply'
        },
        'spec' =>  {
          'values' => {
            'hostname' => { 'value' => 'test.rspec' },
            'analytics' => { 'value' => '0' },
            'accept_eula' => { 'value' => 'has_accepted_eula' },
            'scarp_cpu_request' => { 'value' => '500m' },
            'theq_cpu_request' => { 'value' => '500m' },
          }
        }
      }
    )
  end

  it 'produces a connect config' do
    template_parameters['kots_app'] = 'connect'
    template_parameters['password'] = 'password'
    expect(yaml).to eq(
      {
        'apiVersion' => 'kots.io/v1beta1',
        'kind' => 'ConfigValues',
        'metadata' => {
          'name' => 'connect'
        },
        'spec' =>  {
          'values' => {
            'hostname' => { 'value' => 'test.rspec' },
            'analytics' => { 'value' => '0' },
            'accept_eula' => { 'value' => 'has_accepted_eula' },
            'accept_beta_agreement' => { 'value' => 'has_accepted_beta_agreement' },
            'root_email' => { 'value' => 'noreply@puppet.com' },
            'root_password' => { 'value' => 'password' },
            'connect_postgres_console_memory' => { 'value' => '455' },
            'connect_postgres_puppetdb_memory' => { 'value' => '910' },
            'connect_postgres_orchestrator_memory' => { 'value' => '455' },
            'connect_console_memory' => { 'value' => '1365' },
            'connect_orch_memory' => { 'value' => '1365' },
            'connect_bolt_memory' => { 'value' => '455' },
            'connect_puppetdb_memory' => { 'value' => '1365' },
            'connect_puppetserver_memory' => { 'value' => '1820' },
            'pe_console_cpu_request' => { 'value' => '100m' },
            'pe_orchestrator_cpu_request' => { 'value' => '100m' },
            'pe_puppetdb_cpu_request' => { 'value' => '100m' },
            'pe_puppetserver_cpu_request' => { 'value' => '100m' },
          }
        }
      }
    )
  end
end
