# Install a helm chart.
#
# Optionally adds a helm *repository_uri* before installing.
#
# Optionally waits for rollout of the installed chart based on a
# *part_of* selector.
#
# @param targets
#   Test hosts to deploy to.
# @param chart_name
#   The chart to install.
# @param release
#   The name of the installed instance of the chart.
# @param repository_uri
#   If a helm repository uri is given, ensure it is added and updated on targets
#   before attempting to install the chart. Will take the repository name from
#   the *chart_name* prefix/.
# @param values_yaml
#   Optional yaml string of chart values to pass to Helm.
# @param namespace
#   k8s namespace we're installing into.
# @param part_of
#   If given, plan will wait for rollout of deployments and statefulsets
#   matching 'app.kuberneters.io/part-of=${part_of}' until *timeout*.
# @param timeout
#   Number of seconds to wait for the services to all be ready.
plan pam_tools::install_chart(
  TargetSpec $targets,
  String $chart_name,
  String $release,
  Optional[String] $repository_uri = undef,
  Optional[String] $values_yaml = undef,
  String $namespace = 'default',
  Optional[String] $part_of = undef,
  Integer $timeout = 600,
) {

  if $repository_uri =~ NotUndef {
    $repository_name = regsubst($chart_name, '^([\w-]+)/[\w-]+$', '\1')
    # regsubst() returns the string unchanged if it does not match.
    if $repository_name == $chart_name {
      fail_plan("Expected to find a repository name as the prefix/ in chart_name: '${chart_name}'. Therefore unable to add repository uri '${repository_uri}'.")
    }
    $repo_results = run_task('pam_tools::helm_add_repository', $targets, {
      repository_name => $repository_name,
      repository_uri  => $repository_uri,
    })
  } else {
    $repo_results = 'No repository to add.'
  }

  $install_results = run_task('pam_tools::helm_install_chart', $targets, {
    chart      => $chart_name,
    release    => $release,
    values     => $values_yaml,
    namespace  => $namespace,
  })

  if $part_of =~ NotUndef {
    $wait_results = run_task('pam_tools::wait_for_rollout', $targets, {
      selector  => "app.kubernetes.io/part-of=${part_of}",
      namespace => $namespace,
      timeout   => "${timeout}s",
    })
  } else {
    $wait_results = 'No part_of selector specified; not waiting for rollout.'
  }

  $results = {
    repo_results    => $repo_results,
    install_results => $install_results,
    wait_results    => $wait_results,
  }
  return $results
}
