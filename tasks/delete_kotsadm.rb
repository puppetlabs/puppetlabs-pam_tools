#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Delete the Kots admin-console application from the cluster.
class DeleteKotsadm < PAMTaskHelper

  def task(kots_namespace:, scaledown_timeout:, **_kwargs)
    selector = 'kots.io/kotsadm=true'

    # Attempt to scale down before deletion.
    scaledown_results = scale_down(kots_namespace, selector, scaledown_timeout)
    delete_results = delete_resources(kots_namespace, selector)

    # Clean up a secret that's not caught by the above selector (if it
    # exists).
    delete_secret_results = run_command(['kubectl', 'delete', 'secret/kotsadm-replicated-registry'], false)

    {
      delete_registry_secret_output: delete_secret_results,
    }.merge(scaledown_results).merge(delete_results)
  end
end

DeleteKotsadm.run if __FILE__ == $PROGRAM_NAME
