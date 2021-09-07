#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Remove a Replicated application from a cluster by delete its k8s resources.
class DeleteK8sAppResources < PAMTaskHelper

  def task(kots_slug:, kots_namespace:, scaledown_timeout:, **_kwargs)
    selector = "app.kubernetes.io/part-of=#{kots_slug}"

    # Attempt to scale down before deletion.
    scaledown_results = scale_down(kots_namespace, selector, scaledown_timeout)
    delete_results = delete_resources(kots_namespace, selector)

    {
      kots_slug: kots_slug,
    }.merge(scaledown_results).merge(delete_results)
  end
end

DeleteK8sAppResources.run if __FILE__ == $PROGRAM_NAME
