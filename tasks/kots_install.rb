#! /usr/bin/env ruby

require 'tmpdir'
require 'yaml'
require_relative '../files/pam_task_helper.rb'

# Install a Replicated application via kubectl-kots.
class KotsInstall < PAMTaskHelper
  # Extract the KOTS_SLUG from the license hash.
  def get_slug(license)
    raise(ArgumentError, %(Expected a license hash, but got "#{license}")) if !license.is_a?(Hash)
    spec = license['spec'] || {}
    spec['appSlug']
  end

  # Extract the application name from the license hash.
  def get_appname(license)
    kots_slug = get_slug(license)

    spec = license['spec'] || {}
    entitlements = spec['entitlements'] || {}
    connect = entitlements['connect_entitlement'] || {}
    cd4pe = entitlements['cd_entitlement'] || {}

    (connect['value'] == true && cd4pe['value'] == false) ? 'connect' : kots_slug
  end

  # Generate a base configuration common to our replicated apps.
  def base_config(appname, hostname)
    YAML.safe_load(<<~YAML)
      apiVersion: 'kots.io/v1beta1'
      kind: 'ConfigValues'
      metadata:
        name: '#{appname}'
      spec:
        values:
          hostname:
            value: '#{hostname}'
          analytics:
            value: '0'
          accept_eula:
            value: 'has_accepted_eula'
    YAML
  end

  # Generate root email and password config hash if the app uses it.
  def root_account_config(appname, password)
    if ['cd4pe', 'connect'].include?(appname)
      YAML.safe_load(<<~YAML)
        root_email:
          value: 'noreply@puppet.com'
        root_password:
          value: #{password}
      YAML
    else
      {}
    end
  end

  # Configuration adjustments to fit on our 4cpu/8gb hosts.
  def constraints_config(appname)
    case appname
    when 'connect'
      YAML.safe_load(<<~YAML)
        connect_postgres_console_memory:
          value: '256'
        connect_postgres_puppetdb_memory:
          value: '512'
        connect_postgres_orchestrator_memory:
          value: '256'
        connect_console_memory:
          value: '768'
        connect_orch_memory:
          value: '768'
        connect_bolt_memory:
          value: '256'
        connect_puppetdb_memory:
          value: '768'
        connect_puppetserver_memory:
          value: '1024'
        # These are testing overrides to allow scheduling on a 4cpu test host.
        pe_console_cpu_request:
          value: '100m'
        pe_orchestrator_cpu_request:
          value: '100m'
        pe_puppetdb_cpu_request:
          value: '100m'
        pe_puppetserver_cpu_request:
          value: '100m'
      YAML
    when 'comply'
      YAML.safe_load(<<~YAML)
        scarp_cpu_request:
          value: 500m
        theq_cpu_request:
          value: 500m
      YAML
    else
      {}
    end
  end

  # Generate a default application configuration for installation.
  def generate_config(license, hostname, password)
    appname = get_appname(license)

    config = base_config(appname, hostname)
    spec_values = config['spec']['values']
    spec_values.merge!(root_account_config(appname, password))
    spec_values.merge!(constraints_config(appname))

    config
  end

  # Install the application.
  def task(license_content:, password:, hostname:, kots_namespace:, kots_wait_duration:, config_content: nil, kots_install_options: '', airgap_bundle: nil, pam_variant:, **_kwargs)
    license = YAML.safe_load(license_content)

    config = config_content.nil? ?
      generate_config(license, hostname, password).to_yaml :
      config_content

    kots_command = nil
    output = nil
    # Ensure cleanup of tmpdir and any secrets in the values given.
    Dir.mktmpdir('kots-install') do |tmpdir|
      license_file = File.join(tmpdir, 'license.yaml')
      File.write(license_file, license_content)
      config_file = File.join(tmpdir, 'config.yaml')
      File.write(config_file, config)

      kots_command = [
        'kubectl-kots',
        'install',
        "puppet-application-manager/#{pam_variant}",
        "--namespace=#{kots_namespace}",
        "--shared-password=#{password}",
        '--port-forward=false',
        "--license-file=#{license_file}",
        "--config-values=#{config_file}",
        kots_install_options.to_s.split(' '),
        "--wait-duration=#{kots_wait_duration}",
      ].flatten
      unless airgap_bundle.nil?
        kots_command << "--airgap-bundle=#{airgap_bundle}"
      end
      output = run_command(kots_command)
    end

    {
      appname: get_appname(license),
      command: kots_command.join(' '),
      output: output,
      kots_slug: get_slug(license),
    }
  end
end

KotsInstall.run if __FILE__ == $PROGRAM_NAME
