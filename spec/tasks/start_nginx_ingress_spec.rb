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
    expect(task).to(
      receive(:run_command)
        .with(
          include(
            'kubectl',
            'get',
            'svc/ingress-nginx-controller',
          )
        )
        .and_return('10.20.30.40')
    )

    expect(task.task(args)).to(
      eq(
        {
          command: apply_command.join(' '),
          apply_output: 'applied',
          wait_output: 'waited',
          load_balancer_ip: '10.20.30.40',
        }
      )
    )
  end

  context 'when getting lb ip' do
    let(:timeout) { 1 }
    let(:retries) { 1 }

    before(:each) do
      expect(task).to(
        receive(:run_command)
          .with(
            include(
              'kubectl',
              'get',
              'svc/ingress-nginx-controller',
            )
          )
          .and_return('')
          .exactly(retries).times
      )
    end

    it 'retries ip lookup' do
      expect(task).to(
        receive(:run_command)
          .with(
            include(
              'kubectl',
              'get',
              'svc/ingress-nginx-controller',
            )
          )
          .and_return('10.20.30.40')
      )

      expect(task.task(args)).to(
        match(
          include(
            load_balancer_ip: '10.20.30.40',
          )
        )
      )
    end

    context 'times out' do
      let(:retries) { 2 }

      it 'raises an error if timeout exceeded' do
        expect { task.task(args) }.to raise_error(%r{No loadbalancer IP})
      end
    end
  end
end
