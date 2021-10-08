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

  # Generate a default application configuration for installation.
  def generate_config(license, hostname, password)
    appname = get_appname(license)

    config = base_config(appname, hostname)
    spec_values = config['spec']['values']
    spec_values.merge!(root_account_config(appname, password))

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
