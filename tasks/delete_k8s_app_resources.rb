#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Remove a Replicated application from a cluster by delete its k8s resources.
class DeleteK8sAppResources < PAMTaskHelper

  def task(kots_slug:, kots_namespace:, scaledown_timeout:, **_kwargs)
    app_selector = "app.kubernetes.io/part-of=#{kots_slug}"

    # Attempt to scale down before deletion.
    scaledown_results = scale_down(kots_namespace, app_selector, scaledown_timeout)

    # Delete resources matching these selectors.
    # The k8s selector semantics only allow for logical and of selectors,
    # so to delete three distinct groups, we call kubectl delete three
    # times...
    # https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
    delete_results = []
    [
      app_selector,
      "kots.io/app-slug=#{kots_slug}",
      "app.kubernetes.io/instance=#{kots_slug}-vault",
    ].each do |selector|
      delete_results << delete_resources(kots_namespace, selector)
    end

    {
      kots_slug: kots_slug,
      delete_results: delete_results,
    }.merge(scaledown_results)
  end
end

DeleteK8sAppResources.run if __FILE__ == $PROGRAM_NAME
