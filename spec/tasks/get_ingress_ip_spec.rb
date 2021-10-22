# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/get_ingress_ip.rb'

describe 'pam_tools::get_ingress_ip' do
  let(:task) { GetIngressIP.new }
  let(:port) { 80 }
  let(:timeout) { 0 }
  let(:services) do
    [
      {
        spec: {
          type: 'LoadBalancer',
          ports: [
            {
              port: port,
            },
          ],
        },
        status: {
          loadBalancer: {
            ingress: [
              {
                ip: '10.20.30.40'
              },
            ],
          },
        },
      },
    ]
  end
  let(:args) do
    {
      port: 80,
      timeout: timeout,
    }
  end

  context '#task' do
    before(:each) do
      expect(task).to receive(:run_command).and_return(
        {
          items: services
        }.to_json
      )
    end

    it 'returns the ip' do
      expect(task.task(args)).to eq('10.20.30.40')
    end

    context 'with no match' do
      let(:services) do
        [
          {
            spec: {
              type: 'Foo',
              ports: [
                {
                  port: port,
                },
              ],
            },
          },
          status: {
            loadBalancer: {
              ingress: [
                {
                  ip: '10.20.30.40'
                },
              ],
            },
          },
        ]
      end

      it 'returns nothing' do
        expect(task.task(args)).to be_nil
      end
    end

    context 'with no services' do
      let(:services) { [] }

      it 'returns nothing' do
        expect(task.task(args)).to be_nil
      end
    end

    context 'with a different port' do
      let(:port) { 443 }

      it 'returns nothing for the default 80 port' do
        expect(task.task(args)).to be_nil
      end

      it 'returns an ip if given port 443' do
        args[:port] = 443
        expect(task.task(args)).to eq('10.20.30.40')
      end
    end
  end

  context 'with timeout' do
    let(:unready_service_list) do
      unready = services.first.reject { |k, _v| k == :status }
      {
        items: [ unready ],
      }.to_json
    end
    let(:ready_service_list) do
      {
        items: services
      }.to_json
    end

    it 'retries and succeeds' do
      expect(task).to receive(:run_command).and_return(
        unready_service_list,
        ready_service_list
      )

      args[:timeout] = 2
      expect(task.task(args)).to eq('10.20.30.40')
    end

    it 'retries and raises timeout error' do
      allow(task).to receive(:run_command).and_return(unready_service_list)

      args[:timeout] = 1
      expect { task.task(args) }.to raise_error(PAMTaskHelper::Error)
    end
  end
end
