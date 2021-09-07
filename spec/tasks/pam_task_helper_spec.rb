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

    context 'with execution errors' do
      let(:command_array) { ['oops'] }
      let(:status) { instance_double('Process::Status', success?: false, exitstatus: 1) }

      before(:each) do
        expect(Open3).to receive(:capture2e).with(*command_array).and_return(['err', status])
      end

      it 'exits' do
        expect { helper.run_command(command_array) }.to(
          exit_with(1).and(
            output(%r{Ran: oops.*err}m).to_stdout
          )
        )
      end

      it 'does not exit if asked not to' do
        expect(helper.run_command(command_array, false)).to eq('err')
      end
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
