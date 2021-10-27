# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/delete_kotsadm.rb'

RSpec.shared_context('deleting kotsadm') do
  let(:deletion_response) { "message\none deleted\ntwo deleted" }

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
end

describe 'pam_tools::delete_kotsadm' do
  let(:task) { DeleteKotsadm.new }

  let(:args) do
    {
      kots_namespace: 'default',
      scaledown_timeout: 300,
      force: false,
    }
  end
  let(:scaleable_response) { '' }
  let(:is_kurl) { '' }

  before(:each) do
    allow(task).to receive(:run_command).with(
      array_including(['kubectl', 'get', '--selector=app=kurl-proxy-kotsadm'])
    ).and_return(is_kurl)
  end

  context 'when there is something to delete' do
    include_context('deleting kotsadm')

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

  context 'when this is a kurl host' do
    let(:is_kurl) { 'pod/kurl-proxy-kotsadm-abcde' }

    it 'skips deleting kotsadm' do
      expect(task.task(args)).to eq('Kurl detected, skipping...')
    end

    context 'and forced' do
      include_context('deleting kotsadm')

      it 'deletes' do
        args[:force] = true
        expect(task).not_to receive(:run_command).with(
          array_including(['kubectl', 'get', '--selector=app=kurl-proxy-kotsadm'])
        )

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
end
