# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/has_ingress_controller.rb'

describe 'pam_tools::has_ingress_controller' do
  let(:task) { HasIngressController.new }

  context '#task' do
    let(:kind) { '' }

    before(:each) do
      expect(task).to receive(:run_command).with(
        include('kubectl', 'get', 'service')
      ).and_return({
        items: services
      }.to_json)
      expect(task).to receive(:run_command).with(
        include('kubectl', 'get', 'pod')
      ).and_return(kind)
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

    context 'with a KinD NodePort' do
      let(:kind) { 'pod/kindnet-abcde' }
      let(:services) do
        [
          {
            spec: {
              type: 'NodePort',
              ports: [
                {
                  port: 80,
                  nodePort: 30_000,
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
