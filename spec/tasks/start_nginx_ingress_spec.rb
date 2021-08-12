# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/start_nginx_ingress.rb'

describe 'pam_tools::start_nginx_ingress' do
  let(:task) { StartNginxIngress.new }
  let(:timeout) { 10 }
  let(:args) do
    {
      version: '0.0.0',
      provider: 'spec',
      timeout: timeout,
    }
  end
  let(:source) { 'https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.0.0/deploy/static/provider/spec/deploy.yaml' }
  let(:apply_command) do
    [
      'kubectl',
      'apply',
      "--filename=#{source}",
    ]
  end

  it 'runs' do
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

    expect(task.task(args)).to(
      eq(
        {
          command: apply_command.join(' '),
          apply_output: 'applied',
          wait_output: 'waited',
        }
      )
    )
  end
end
