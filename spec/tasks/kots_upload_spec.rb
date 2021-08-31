# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/kots_upload.rb'

describe 'kurl_test::kots_upload' do
  let(:task) { KotsUpload.new }
  let(:args) do
    {
      kots_slug: 'app',
      kots_namespace: 'default',
    }
  end
  let(:command_args) do
    [
      'kubectl-kots',
      'upload',
      '/tmp/app',
      '--namespace=default',
      '--slug=app',
    ]
  end

  context '#task' do
    before(:each) do
      expect(task).to receive(:run_command).with(command_args).and_return('uploaded')
    end

    it 'runs' do
      expect(task.task(args)).to include(output: 'uploaded')
    end

    it 'sets source dir' do
      args[:source] = '/tmp/somewhere'
      command_args[2] = '/tmp/somewhere'

      expect(task.task(args)).to include(output: 'uploaded')
    end

    it 'deploys' do
      args[:deploy] = true
      command_args << '--deploy'

      expect(task.task(args)).to include(output: 'uploaded')
    end

    it 'skips-preflights' do
      args[:skip_preflights] = true
      command_args << '--skip-preflights'

      expect(task.task(args)).to include(output: 'uploaded')
    end
  end
end
