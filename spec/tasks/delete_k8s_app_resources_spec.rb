# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/delete_k8s_app_resources.rb'

describe 'pam_tools::delete_k8s_app_resources' do
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
      ).and_return('list of things').exactly(3).times
      expect(task).to receive(:run_command).with(
        [
          'kubectl',
          'get',
          'deployments,statefulsets',
          '--output=name',
          '--namespace=default',
          '--selector=app.kubernetes.io/part-of=app',
        ]
      ).and_return(scaleable_response)
      [
        'app.kubernetes.io/part-of=app',
        'kots.io/app-slug=app',
        'app.kubernetes.io/instance=app-vault',
      ].each do |s|
        expect(task).to receive(:run_command).with(
          include(
            'kubectl',
            'delete',
            'list,of,things',
            '--wait=true',
            '--namespace=default',
            "--selector=#{s}",
          )
        ).and_return(deletion_response)
      end
    end

    context 'when there is something to delete' do
      let(:deletion_response) { "message\none deleted\ntwo deleted" }

      it 'deletes the k8s application resources' do
        expect(task.task(args)).to include(
          kots_slug: 'app',
          messages_from_scale: ['No deployments or statefulsets to scale down.'],
          delete_results: [
            include(
              delete_command: %r{kubectl delete.*--selector=app\.kubernetes\.io/part-of=app},
              deleted: [ 'one deleted', 'two deleted' ],
              messages_from_delete: [ 'message' ],
            ),
            include(
              delete_command: %r{kubectl delete.*--selector=kots\.io/app-slug=app},
              deleted: [ 'one deleted', 'two deleted' ],
              messages_from_delete: [ 'message' ],
            ),
            include(
              delete_command: %r{kubectl delete.*--selector=app\.kubernetes\.io/instance=app-vault},
              deleted: [ 'one deleted', 'two deleted' ],
              messages_from_delete: [ 'message' ],
            ),
          ],
        )
      end
    end

    context 'when there is nothing to delete' do
      let(:deletion_response) { "message\nnothing to delete" }

      it 'returns just messages' do
        expect(task.task(args)).to include(
          kots_slug: 'app',
          delete_results: [
            include(
              messages_from_delete: [ 'message', 'nothing to delete' ],
            ),
            include(
              messages_from_delete: [ 'message', 'nothing to delete' ],
            ),
            include(
              messages_from_delete: [ 'message', 'nothing to delete' ],
            ),
          ],
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
            'deployments,statefulsets',
            '--replicas=0',
            '--timeout=300s',
            '--namespace=default',
            '--selector=app.kubernetes.io/part-of=app',
          ]
        ).and_return("one scaled\n")

        expect(task.task(args)).to include(
          kots_slug: 'app',
          delete_results: [
            include(
              deleted: [ 'one deleted' ],
            ),
            include(
              deleted: [ 'one deleted' ],
            ),
            include(
              deleted: [ 'one deleted' ],
            ),
          ],
          scaled: ['one scaled'],
        )
      end
    end
  end
end
