# frozen_string_literal: true

require 'spec_helper'
require_relative '../../files/pam_task_helper.rb'

describe 'PAMTaskHelper' do
  let(:helper) { PAMTaskHelper.new }

  context '#run_command' do
    it 'runs and returns output' do
      command_array = ['foo', 'bar']
      success = instance_double('Process::Status', success?: true, exitstatus: 0)
      expect(Open3).to receive(:capture2e).with(*command_array).and_return(['stdout', success])
      expect(helper.run_command(command_array)).to eq('stdout')
    end

    it 'runs for real' do
      expect(helper.run_command(['true'])).to eq('')
    end

    it 'exits for execution errors' do
      command_array = ['oops']
      success = instance_double('Process::Status', success?: false, exitstatus: 1)
      expect(Open3).to receive(:capture2e).with(*command_array).and_return(['err', success])
      expect { helper.run_command(command_array) }.to(
        exit_with(1).and(
          output(%r{Ran: oops.*err}m).to_stdout
        )
      )
    end

    it 'handles actual failures' do
      expect { helper.run_command(['false']) }.to(
        exit_with(1).and(
          output(%r{Ran: false}).to_stdout
        )
      )
    end
  end
end
