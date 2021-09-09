# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/list_container_images.rb'

describe 'pam_tools::list_container_images' do
  let(:task) { ListContainerImages.new }
  let(:args) do
    {
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

  it 'lists images' do
    expect(task).to receive(:get_deployments_and_statefulsets)
    expect(task).to receive(:list_container_images).and_return(container_images)

    expect(task.task(args)).to eq(
      containers: [
        'some/bar:0.0.1 deployment.apps/two containers:container2',
        'some/foo:0.0.1 deployment.apps/one containers:container1',
      ]
    )
  end
end
