# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/start_nginx_ingress.rb'

describe 'pam_tools::start_nginx_ingress' do
  let(:task) { StartNginxIngress.new }
  let(:args) do
    {
      version: '0.0.0',
      provider: 'spec',
      timeout: '1',
    }
  end
  let(:source) { 'https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.0.0/deploy/static/provider/spec/deploy.yaml' }

  it 'runs' do
    apply_command = [
      'kubectl',
      'apply',
      "--filename=#{source}",
    ]
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
            '--timeout=1s',
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
