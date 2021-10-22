#! /usr/bin/env ruby

require 'tmpdir'
require 'yaml'
require_relative '../files/pam_task_helper.rb'

# Install or upgrade a Helm chart.
class HelmInstallChart < PAMTaskHelper
  def task(chart:, release:, namespace:, version: nil, values: nil, **_kwargs)
    install_command = [
      'helm',
      'upgrade',
      release,
      chart,
      '--install',
      "--namespace=#{namespace}",
    ]
    install_command << "--version=#{version}" if !version.nil?

    install_result = nil
    # Ensure cleanup of tmpdir and any secrets in the values given.
    Dir.mktmpdir('helm-install') do |tmpdir|
      if !values.nil?
        values_yaml = YAML.safe_load(values) # ensure it's valid YAML
        values_file = File.join(tmpdir, 'value-overrides.yaml')
        File.write(values_file, values_yaml.to_yaml)
        install_command << "--values=#{values_file}"
      end

      install_result = run_command(install_command)
    end

    {
      command: install_command.join(' '),
      results: install_result,
    }
  end
end

HelmInstallChart.run if __FILE__ == $PROGRAM_NAME
