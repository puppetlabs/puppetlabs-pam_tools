# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/has_ingress_controller.rb'

describe 'pam_tools::has_ingress_controller' do
  let(:task) { HasIngressController.new }

  context '#task' do
    before(:each) do
      expect(task).to receive(:run_command).with(any_args).and_return({
        items: services
      }.to_json)
    end

    context 'with LoadBalancer' do
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

    context 'with NodePort' do
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

      it 'returns true' do
        expect(task.task).to eq(false)
      end
    end

    context 'with nothing' do
      let(:services) { [] }

      it 'returns true' do
        expect(task.task).to eq(false)
      end
    end
  end
end
