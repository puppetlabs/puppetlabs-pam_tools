# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../../tasks/helm_install_chart.rb'

describe 'pam_tools::helm_install_chart' do
  let(:task) { HelmInstallChart.new }
  let(:args) do
    {
      chart: 'test/chart',
      release: 'test-release',
      namespace: 'default',
      kubeconfig: '~/.kube/config',
    }
  end
  let(:helm_args) do
    [
      'helm',
      'upgrade',
      'test-release',
      'test/chart',
      '--install',
      '--namespace=default',
      %r{--kubeconfig=.*/.kube/config},
    ]
  end

  before(:each) do
    expect(task).to receive(:run_command).with(
      match(helm_args)
    ).and_return('installed')
  end

  it 'installs a chart' do
    expect(task.task(args)).to match(
      {
        command: %r{helm upgrade test-release.*},
        results: 'installed',
      }
    )
  end

  it 'installs a chart with a version' do
    args[:version] = '1.2.3'
    helm_args << '--version=1.2.3'

    expect(task.task(args)).to match(
      {
        command: %r{helm upgrade test-release.*--version=1\.2\.3},
        results: 'installed',
      }
    )
  end

  it 'installs a chart with values' do
    args[:values] = "---\nfoo: bar\n"
    helm_args << %r{--values=.*/value-overrides.yaml}

    expect(task.task(args)).to match(
      {
        command: %r{helm upgrade test-release.*--values=.*/value-overrides\.yaml},
        results: 'installed',
      }
    )
    # Validate that we're not leaving behind tmpdirs with value-overrides.yaml
    # since these could include secrets.
    expect(Dir.glob("#{Dir.tmpdir}/helm-install*")).to be_empty
  end
end
