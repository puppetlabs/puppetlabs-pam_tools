# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/delete_kotsadm.rb'

describe 'pam_tools::delete_kotsadm' do
  let(:task) { DeleteKotsadm.new }

  let(:args) do
    {
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
        'deployments,statefulsets',
        '--output=name',
        '--namespace=default',
        '--selector=kots.io/kotsadm=true',
      ]
    ).and_return(scaleable_response)
    expect(task).to receive(:run_command).with(
      [
        'kubectl',
        'delete',
        'list,of,things',
        '--wait=true',
        '--namespace=default',
        '--selector=kots.io/kotsadm=true',
      ]
    ).and_return(deletion_response)
    expect(task).to receive(:run_command).with(
      [
        'kubectl',
        'delete',
        'secret/kotsadm-replicated-registry',
      ],
      false
    )
  end

  context 'when there is something to delete' do
    let(:deletion_response) { "message\none deleted\ntwo deleted" }

    it 'deletes the k8s application resources' do
      expect(task.task(args)).to include(
        messages_from_delete: ['message'],
        deleted: [
          'one deleted',
          'two deleted',
        ],
      )
    end
  end
end
