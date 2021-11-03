# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/has_ingress_controller.rb'

describe 'pam_tools::has_ingress_controller' do
  let(:task) { HasIngressController.new }
  let(:pods) { nil }

  context '#task' do
    before(:each) do
      expect(task).to receive(:run_command).with(
        include('kubectl', 'get', 'service')
      ).and_return({
        items: services
      }.to_json)

      if !pods.nil?
        expect(task).to receive(:run_command).with(
          include('kubectl', 'get', 'pod')
        ).and_return({
          items: pods
        }.to_json)
      end
    end

    context 'with LoadBalancer service' do
      let(:services) do
        [
          {
            spec: {
              type: 'LoadBalancer',
              ports: [
                {
                  port: 80,
                },
              ],
            },
          },
        ]
      end

      it 'returns true' do
        expect(task.task).to eq(true)
      end
    end

    context 'with NodePort service' do
      let(:services) do
        [
          {
            spec: {
              type: 'NodePort',
              ports: [
                {
                  nodePort: 80,
                },
              ],
            },
          },
        ]
      end

      it 'returns true' do
        expect(task.task).to eq(true)
      end
    end

    context 'with a pod hostPort' do
      let(:services) { [] }
      let(:pods) do
        [
          {
            spec: {
              containers: [
                {
                  ports: [
                    {
                      hostPort: 80,
                    },
                  ],
                },
              ],
            },
          },
        ]
      end

      it 'returns true' do
        expect(task.task).to eq(true)
      end
    end

    context 'with no matches' do
      let(:services) do
        [
          {
            spec: {
              type: 'ClusterIP',
              ports: [
                {
                  port: 80,
                },
              ],
            },
          },
          {
            spec: {
              type: 'LoadBalancer',
              ports: [
                {
                  port: 8080,
                },
              ],
            },
          },
          {
            spec: {
              type: 'NodePort',
              ports: [
                {
                  nodePort: 8800,
                },
              ],
            },
          },
        ]
      end
      let(:pods) do
        [
          {
            spec: {
              containers: [
                {
                  ports: [
                    {
                      hostPort: 3000,
                    },
                  ],
                },
              ],
            },
          },
        ]
      end

      it 'returns true' do
        expect(task.task).to eq(false)
      end
    end

    context 'with containers without ports' do
      let(:services) { [] }
      let(:pods) do
        [
          {
            spec: {
              containers: [
                {},
              ],
            },
          },
        ]
      end

      it 'returns true' do
        expect(task.task).to eq(false)
      end
    end

    context 'with nothing' do
      let(:services) { [] }
      let(:pods) { [] }

      it 'returns true' do
        expect(task.task).to eq(false)
      end
    end
  end
end
