#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Delete the Kots admin-console application from the cluster.
class DeleteKotsadm < PAMTaskHelper

  # @return [Boolean] true if we detect a kurl-proxy pod running, which is an
  # in-cluster guess for this having been set up by Kurl.
  def kurl_cluster?(kots_namespace)
    get_kurl_proxy_pod_command = [
      'kubectl',
      'get',
      'pod',
      "--namespace=#{kots_namespace}",
      '--selector=app=kurl-proxy-kotsadm',
      '--output=name',
    ]
    !run_command(get_kurl_proxy_pod_command).empty?
  end

  def task(kots_namespace:, scaledown_timeout:, force:, **_kwargs)
    # Skip deleting kotsadm if this is a Kurl cluster, because reinstalling
    # Kots will not set the kurl-proxy back up. Do it anyway if told to.
    if force || !kurl_cluster?(kots_namespace)
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
    else
      'Kurl detected, skipping...'
    end
  end
end

DeleteKotsadm.run if __FILE__ == $PROGRAM_NAME
