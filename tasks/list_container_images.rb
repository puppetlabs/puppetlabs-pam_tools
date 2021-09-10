#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# List image references from deployments and statefulsets in the passed namespace.
class ListContainerImages < PAMTaskHelper

  def task(kots_namespace:, **_kwargs)
    deployments_and_statefulsets = get_deployments_and_statefulsets(kots_namespace)
    container_images = list_container_images(deployments_and_statefulsets, kots_namespace)

    {
      containers: container_images.sort_by(&:image_name).map(&:to_s)
    }
  end
end

ListContainerImages.run if __FILE__ == $PROGRAM_NAME
