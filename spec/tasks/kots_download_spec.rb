# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/kots_download.rb'

describe 'kurl_test::kots_download' do
  let(:task) { KotsDownload.new }
  let(:args) do
    {
      kots_slug: 'app',
      kots_namespace: 'default',
    }
  end
  let(:command_args) do
    [
      'kubectl-kots',
      'download',
      'app',
      '--namespace=default',
      '--dest=/tmp/app',
      '--overwrite',
    ]
  end

  context '#task' do
    before(:each) do
      expect(task).to receive(:run_command).with(command_args).and_return('downloaded')
    end

    it 'runs' do
      expect(task.task(args)).to include(
        output: 'downloaded'
      )
    end

    it 'sets destination dir' do
      args[:destination] = '/tmp/somewhere'
      command_args[4] = '--dest=/tmp/somewhere'

      expect(task.task(args)).to include(
        output: 'downloaded'
      )
    end

    it 'clears upstream source after download' do
      args[:clear_upstream] = true

      expect(Dir).to receive(:glob).with('/tmp/app/app/upstream/*.yaml')
        .and_return(%w[/tmp/app/app/upstream/a.yaml /tmp/app/app/upstream/b.yaml])
      expect(File).to receive(:delete).with('/tmp/app/app/upstream/a.yaml')
      expect(File).to receive(:delete).with('/tmp/app/app/upstream/b.yaml')

      expect(task.task(args)).to include(
        output: 'downloaded',
        messages: 'Removed /tmp/app/app/upstream/*.yaml',
      )
    end
  end
end
