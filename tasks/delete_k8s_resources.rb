#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Remove a set of resources for a cluster by selected labels.
class DeleteK8sResources < PAMTaskHelper
  def task(selector:, kots_namespace:, **_kwargs)
    delete_resources(kots_namespace, selector)
  end
end

DeleteK8sResources.run if __FILE__ == $PROGRAM_NAME
