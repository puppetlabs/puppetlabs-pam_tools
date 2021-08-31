# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/delete_k8s_app_resources.rb'

describe 'kurl_test::delete_k8s_app_resources' do
  let(:task) { DeleteK8sAppResources.new }

  context '#task' do
    let(:args) do
      {
        kots_slug: 'app',
        kots_namespace: 'default',
        scaledown_timeout: 300,
      }
    end
    let(:scaleable_response) { '' }

    before(:each) do
      expect(task).to receive(:run_command).with(
        array_including(['kubectl', 'api-resources'])
      ).and_return('list of things')
      expect(task).to receive(:run_command).with(
        [
          'kubectl',
          'get',
          'deployments,replicasets,statefulsets',
          '--output=name',
          '--namespace=default',
          '--selector=app.kubernetes.io/part-of=app',
        ]
      ).and_return(scaleable_response)
      expect(task).to receive(:run_command).with(
        [
          'kubectl',
          'delete',
          'list,of,things',
          '--wait=true',
          '--namespace=default',
          '--selector=app.kubernetes.io/part-of=app',
        ]
      ).and_return(deletion_response)
    end

    context 'when there is something to delete' do
      let(:deletion_response) { "message\none deleted\ntwo deleted" }

      it 'deletes the k8s application resources' do
        expect(task.task(args)).to include(
          kots_slug: 'app',
          messages_from_delete: ['message'],
          deleted: [
            'one deleted',
            'two deleted',
          ],
        )
      end
    end

    context 'when there is nothing to delete' do
      let(:deletion_response) { "message\nnothing to delete" }

      it 'returns just messages' do
        expect(task.task(args)).to include(
          kots_slug: 'app',
          messages_from_delete: ['message', 'nothing to delete'],
        )
      end
    end

    context 'when there is something to scale' do
      let(:scaleable_response) { 'one' }
      let(:deletion_response) { "one deleted\n" }

      it 'scales down and deletes' do
        expect(task).to receive(:run_command).with(
          [
            'kubectl',
            'scale',
            'deployments,replicasets,statefulsets',
            '--replicas=0',
            '--namespace=default',
            '--selector=app.kubernetes.io/part-of=app',
          ]
        ).and_return("one scaled\n")
        expect(task).to receive(:run_command).with(
          [
            'kubectl',
            'wait',
            'pod',
            '--for=delete',
            '--timeout=300s',
            '--namespace=default',
            '--selector=app.kubernetes.io/part-of=app',
          ]
        )

        expect(task.task(args)).to include(
          kots_slug: 'app',
          deleted: ['one deleted'],
          scaled: ['one scaled'],
        )
      end
    end
  end
end
