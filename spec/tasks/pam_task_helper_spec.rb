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

  context '.run' do
    class TestTask < PAMTaskHelper
      def task(**kwargs)
        { inputs: kwargs }
      end
    end

    let(:output_hash) { { thing: 'done' } }

    it 'installs' do
      json_input = '{"foo":"bar"}'
      output_hash = { inputs: { 'foo' => 'bar' } }

      expect($stdin).to receive(:read).and_return(json_input)

      expect { TestTask.run }.to(
        output(output_hash.to_json.to_s).to_stdout
      )
    end
  end

  context '#list_container_images' do
    let(:deployment) { 'deployment.apps/thing1' }
    let(:statefulset) { 'statefulset.apps/stateful-thing2' }
    let(:resources) do
      [
        deployment,
        statefulset,
      ]
    end

    it 'returns a list of container hash information' do
      expect(helper).to receive(:run_command).with(
        include(
          'deployment.apps/thing1',
          %r{jsonpath.*\.containers\[}
        )
      ).and_return(
        "container1,some/image:1.2.3\n"
      )
      expect(helper).to receive(:run_command).with(
        include(
          'deployment.apps/thing1',
          %r{jsonpath.*\.initContainers\[}
        )
      ).and_return('')

      expect(helper).to receive(:run_command).with(
        include(
          'statefulset.apps/stateful-thing2',
          %r{jsonpath.*\.containers\[}
        )
      ).and_return(
        <<~EOS
          stateful-container1,some/other-image:1.0.0
          stateful-container2,some/foo:1.0.0
        EOS
      )
      expect(helper).to receive(:run_command).with(
        include(
          'statefulset.apps/stateful-thing2',
          %r{jsonpath.*\.initContainers\[}
        )
      ).and_return(
        "init-container1,bar:0.0.5\n",
      )

      expect(helper.list_container_images(resources, 'default').map(&:to_h)).to match_array(
        [
          {
            namespace: 'default',
            resource: deployment,
            container_type: 'containers',
            container_name: 'container1',
            image: 'some/image:1.2.3',
          },
          {
            namespace: 'default',
            resource: statefulset,
            container_type: 'containers',
            container_name: 'stateful-container1',
            image: 'some/other-image:1.0.0',
          },
          {
            namespace: 'default',
            resource: statefulset,
            container_type: 'containers',
            container_name: 'stateful-container2',
            image: 'some/foo:1.0.0',
          },
          {
            namespace: 'default',
            resource: statefulset,
            container_type: 'initContainers',
            container_name: 'init-container1',
            image: 'bar:0.0.5',
          },
        ]
      )
    end

    it 'returns an empty array if given one' do
      expect(helper.list_container_images([], 'default')).to eq([])
    end
  end

  context 'ContainerImage' do
    let(:image) do
      PAMTaskHelper::KubectlCommands::ContainerImage.new(
        namespace: 'default',
        resource: 'deployment.apps/foo',
        container_type: 'containers',
        container_name: 'bar',
        image: 'some/thing/interesting:1.2.3',
      )
    end

    it 'provides an #id' do
      expect(image.id).to eq('default,deployment.apps/foo,containers:bar,some/thing/interesting')
    end

    it 'returns just the #image_name' do
      expect(image.image_name).to eq('some/thing/interesting')
    end

    it 'finds an image match' do
      expect(image.matches?('interesting')).to eq(true)
      expect(image.matches?('thing/interesting')).to eq(true)
    end

    it 'rejects an image mismatch' do
      expect(image.matches?('dingos')).to eq(false)
      expect(image.matches?('interest')).to eq(false)
    end

    it 'patches the image version' do
      expect(PAMTaskHelper).to receive(:run_command).with(
        [
          'kubectl',
          'patch',
          'deployment.apps/foo',
          '--namespace=default',
          '--patch={"spec":{"template":{"spec":{"containers":[{"name":"bar","image":"some/thing/interesting:4.5.6"}]}}}}',
        ]
      ).and_return('patched')

      expect(image.patch_version('4.5.6')).to match(
        image: 'default,deployment.apps/foo,containers:bar,some/thing/interesting',
        new_version: '4.5.6',
        command: match(%r{kubectl patch.*}),
        patch_result: 'patched',
      )
    end

    it 'prints a #to_s' do
      expect(image.to_s).to eq('some/thing/interesting:1.2.3 deployment.apps/foo containers:bar')
    end
  end
end
