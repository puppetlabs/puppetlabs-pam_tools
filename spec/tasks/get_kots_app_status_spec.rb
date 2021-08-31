# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/get_kots_app_status.rb'

describe 'kurl_test::get_kots_app_status' do
  let(:task) { GetKotsAppStatus.new }

  let(:args) do
    {
      kots_slug: 'app',
      kots_namespace: 'default',
      verbose: false,
    }
  end
  let(:apps_hash) do
    <<~EOS
      [
          {
              "slug": "app",
              "state": "ready"
          }
      ]
    EOS
  end

  context '#task' do
    before(:each) do
      expect(task).to receive(:run_command).with(
        [
          'kubectl-kots',
          'get',
          'apps',
          '--namespace=default',
          '--output=json',
        ]
      ).and_return(apps_hash)
    end

    it 'returns short status' do
      expect(task.task(args)).to eq('ready')
    end

    it 'returns verbose status' do
      args[:verbose] = true
      expect(task.task(args)).to eq(
        {
          kots_slug: 'app',
          app_state: 'ready',
          app_status_list: [
            {
              'slug'  => 'app',
              'state' => 'ready',
            },
          ],
        }
      )
    end

    context 'when not installed' do
      let(:apps_hash) do
        <<~EOS
          [
              {
                  "slug": "somethingelse",
                  "state": "ready"
              }
          ]
        EOS
      end

      it 'returns not-installed' do
        expect(task.task(args)).to eq('not-installed')
      end
    end
  end
end
