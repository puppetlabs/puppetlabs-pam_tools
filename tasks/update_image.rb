#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Patch a given pod container image to the passed reference.
class UpdateImage < PAMTaskHelper

  def task(image_name:, image_version:, kots_namespace:, **_kwargs)
    deployments_and_statefulsets = get_deployments_and_statefulsets(kots_namespace)
    container_images = list_container_images(deployments_and_statefulsets, kots_namespace)

    patch_results = container_images.map do |image|
      if image.matches?(image_name)
        image.patch_version(image_version)
      end
    end.compact

    {
      image_name: image_name,
      image_version: image_version,
      all_images_found: container_images.sort_by(&:image).map(&:id),
      patched: patch_results,
    }
  end
end

UpdateImage.run if __FILE__ == $PROGRAM_NAME
