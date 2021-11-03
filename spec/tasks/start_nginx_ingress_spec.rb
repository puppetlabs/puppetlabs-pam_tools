# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/start_nginx_ingress.rb'

describe 'pam_tools::start_nginx_ingress' do
  let(:task) { StartNginxIngress.new }
  let(:timeout) { 10 }
  let(:provider) { 'spec' }
  let(:args) do
    {
      version: '0.0.0',
      provider: provider,
      timeout: timeout,
    }
  end
  let(:source) { "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.0.0/deploy/static/provider/#{provider}/deploy.yaml" }
  let(:apply_command) do
    [
      'kubectl',
      'apply',
      "--filename=#{source}",
    ]
  end
  let(:task_result) do
    {
      command: apply_command.join(' '),
      apply_output: 'applied',
      wait_output: 'waited',
    }
  end

  before(:each) do
    expect(task).to(
      receive(:run_command)
        .with(apply_command)
        .and_return('applied')
    )
    expect(task).to(
      receive(:run_command)
        .with(
          include(
            'kubectl',
            'rollout',
            "--timeout=#{timeout}s",
          )
        )
        .and_return('waited')
    )
  end

  it 'runs' do
    expect(task.task(args)).to(
      eq(task_result)
    )
  end

  context 'without provider specified' do
    let(:provider) { 'cloud' }
    let(:kind) { '' }

    before(:each) do
      args.delete(:provider)

      expect(task).to receive(:run_command).with(
        include('kubectl', 'get', 'pod')
      ).and_return(kind)
    end

    it 'installs cloud provider by default' do
      expect(task.task(args)).to(
        eq(task_result)
      )
    end

    context 'but with a KinD cluster' do
      let(:provider) { 'kind' }
      let(:kind) { 'pod/kindnet-abcde' }

      it 'installs kind provider by default' do
        expect(task.task(args)).to(
          eq(task_result)
        )
      end
    end
  end
end
