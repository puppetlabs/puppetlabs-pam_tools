# In successive tiers, teardown the application, it's admin-console
# metadata, and the Kots admin-console itself, if desired.
#
# By default, just deletes the given app's resources, allowing
# for a fresh deployment.
#
# @param targets
#   The hosts to operate on.
# @param kots_slug
#   The slug label of the Replicated application to delete.
# @param kots_namespace
#   The k8s namespace the application is installed in.
# @param scaledown_timeout
#   The number of seconds to wait for the application to scale down while
#   deleting resources.
# @param remove_app_from_console
#   If true, then the application metadata will also be deleted from the
#   admin-console. The next installation via `kubectl-kots install` will
#   recreate a fresh entry for the application in the console.
# @param delete_kotsadm
#   If true, then the Kotsadm admin-console will also be deleted from
#   the cluster. It should be reinstalled by the next `kubectl-kots install`
#   command.
plan pam_tools::teardown(
  TargetSpec $targets,
  String $kots_slug,
  String $kots_namespace = 'default',
  Integer $scaledown_timeout = 300,
  Boolean $remove_app_from_console = false,
  Boolean $delete_kotsadm = false,
) {

  $destroy_app_results = run_task('pam_tools::delete_k8s_app_resources', $targets, {
    'kots_slug'         => $kots_slug,
    'kots_namespace'    => $kots_namespace,
    'scaledown_timeout' => $scaledown_timeout,
  })

  if $remove_app_from_console {
    $remove_app_from_console_results = run_task('pam_tools::delete_kots_app', $targets, {
      'kots_slug'      => $kots_slug,
      'kots_namespace' => $kots_namespace,
      'force'          => true,
    })
  } else {
    $remove_app_from_console_results = 'not-done'
  }

  if $delete_kotsadm {
    $delete_kotsadm_results = run_task('pam_tools::delete_kotsadm', $targets, {
      'kots_namespace'    => $kots_namespace,
      'scaledown_timeout' => $scaledown_timeout,
    })
  } else {
    $delete_kotsadm_results = 'not-done'
  }

  $results = {
    'kots_slug'                          => $kots_slug,
    'destroy_app_result_set'             => $destroy_app_results,
    'remove_app_from_console_result_set' => $remove_app_from_console_results,
    'delete_kotsadm_result_set'          => $delete_kotsadm_results,
  }
  return $results
}
