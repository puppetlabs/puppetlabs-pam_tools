# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/update_image.rb'

describe 'pam_tools::update_image' do
  let(:task) { UpdateImage.new }
  let(:args) do
    {
      image_name: 'foo',
      image_version: '1.2.3',
      kots_namespace: 'default',
    }
  end
  let(:container_images) do
    [
      PAMTaskHelper::KubectlCommands::ContainerImage.new(
        namespace: 'default',
        resource: 'deployment.apps/one',
        container_type: 'containers',
        container_name: 'container1',
        image: 'some/foo:0.0.1',
      ),
      PAMTaskHelper::KubectlCommands::ContainerImage.new(
        namespace: 'default',
        resource: 'deployment.apps/two',
        container_type: 'containers',
        container_name: 'container2',
        image: 'some/bar:0.0.1',
      ),
    ]
  end

  it 'runs' do
    expect(task).to(
      receive(:get_deployments_and_statefulsets).and_return('deployment.apps/one')
    )
    expect(task).to receive(:list_container_images).and_return(container_images)
    expect(PAMTaskHelper).to(
      receive(:run_command).with(
        include(
          match(%r{--patch=.*"image":"some/foo:1\.2\.3"}),
        )
      ).and_return('patched')
    )

    expect(task.task(args)).to include(
      image_name: 'foo',
      image_version: '1.2.3',
      patched: [
        include(
          patch_result: 'patched',
        ),
      ]
    )
  end
end
