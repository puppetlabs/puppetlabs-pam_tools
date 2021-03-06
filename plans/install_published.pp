# Install a published Replicated application via kubectl-kots.
#
# Runs kubectl-kots with the given license and configuration and waits for
# deployment.
#
# The `kubectl-kots install` installs the Replicated Kots admin-console as
# a side effect if not already installed into the cluster. Initial configuration
# for Kots comes from one of the puppet-application-manager channels as determined
# by the +pam_variant+ parameter. By default Kots is installed with
# puppet-application-manager/stable.
#
# If a password is given, it is used for the Kots admin-console admin login.
# If no password is given, one will be randomly generated and output at the end
# of the plan for reference.
#
# If no application configuration file is given, a very basic configuration file is
# generated using [this template](./templates/default-app-config.yaml.epp).
#
# In the case of cd4pe/cygnus installs, the same password and a root login of
# noreply@puppet.com are set in the generated configuration. If a custom
# +config_file+ is provided, it is assumed to be complete, and is used instead.
#
# One of the key configuration parameters in the application configuration
# is the hostname used in the cert and ingress. If a +config_file+ is provided,
# hostname should be set there and will take precedence.
#
# Alternately, +hostname+ can be set as a parameter, and will be set
# in the generated config if no +config_file+ is given.
#
# Generally, when working with test hosts, no +config_file+ is given, and
# +hostname+ is left unset. In this case, the app hostname parameter is
# populated based on the target automatically, using either the target's
# hostname in the case of ssh targets, or by generating a wildcard dns hostname
# that will be recognized by [nip.io](https://nip.io) based on the app name and
# a lookup of the cluster's ingress load balancer ip. This will be something
# like cd4pe.10.20.30.40.nip.io, ensuring a connection on 10.20.30.40.
#
# Because `kubectl-kots install` is not an idempotent operation, if the plan
# detects that the application has already been installed, it will skip this
# step and simply wait for the application to be ready.
#
# @param targets
#   The hosts to operate on.
# @param license_file
#   Path to the application license file.
# @param password
#   Password to use for both the Kots admin-console and for the application itself
#   (if not present in the config_file). If no password is given, one will be
#   randomly generated.
# @param config_file
#   Absolute path to application configuration defaults. If not provided, a
#   basic config will be generated by the install task.
# @param airgap_bundle
#   Installs the application from an airgap bundle. Must be an absolute path.
# @param hostname
#   The application hostname to set in a generated configuration. Ignored if
#   +config_file+ given. Otherwise generated from target if not set (see
#   above).
# @param webhook_hostname
#   For applications that present a webhook, hosts the webhook on a separate
#   Ingress at the specified hostname rather than an external port.
# @param kots_install_options
#   Any additional command line options to pass directly to `kubectl-kots
#   install` when the kots_install task is run. (--skip-preflights=true, or
#   --skip-rbac-check=true, for example...)
# @param pam_variant
#   The initial puppet-application-manager channel that will provide
#   configuration for Kots itself prior to Kots installing the application
#   identified by the +license_content+. This can be important for a
#   GKE cluster, for example, which will require 'minimal-rbac' instead of
#   'stable' unless the service-account used has permissions to modify
#   clusteroles.
# @param allocated_memory_in_gigabytes
#   The total system memory being made available to the application.
#   This should be in integer or float gigabytes. This is used to
#   tune configuration for the app. It will be ignored if you are
#   supplying your own +config_file+, or for any application other
#   than Connect.
# @param allocated_cpu
#   The total number of cpu available to the application. This should
#   be whole or Float fractional cpu, but not millicpu. Currently the
#   only affect is to tighten comply cpu requests to allow it to stand up
#   with <= 4 cpu.
# @param wait_for_app
#   Whether or not to wait for app deployment to complete before returning.
# @param app_timeout
#   If waiting for the app, this is the number of seconds to wait for kots
#   to indicate that the app is ready.
plan pam_tools::install_published(
  TargetSpec $targets,
  Pam_tools::Absolute_path $license_file,
  Optional[String[6]] $password = undef,
  Optional[Pam_tools::Absolute_path] $config_file = undef,
  Optional[Pam_tools::Absolute_path] $airgap_bundle = undef,
  Optional[String] $hostname = undef,
  Optional[String] $webhook_hostname = undef,
  Optional[String] $kots_install_options = undef,
  String $pam_variant = 'stable',
  Variant[Integer,Float] $allocated_memory_in_gigabytes = 16,
  Variant[Integer,Float] $allocated_cpu = 8,
  Boolean $wait_for_app = true,
  Integer $app_timeout = 600,
) {
  # Sanity check given files.
  pam_tools::check_for_file('License', $license_file)
  pam_tools::check_for_file('Config', $config_file, false)
  pam_tools::check_for_file('Bundle', $airgap_bundle, false)

  ##########################################
  # Ensure we have Ingress controllers setup
  # Allows us to later reach the app on http for an eventual health check.
  # Kurl hosts will have this, gke, k3s or kind likely will need it installed.
  $have_ingress_controllers = run_task('pam_tools::has_ingress_controller', $targets)
  $no_ingress_targets = $have_ingress_controllers.filter_set() |$result| {
    $result.message() == 'false'
  }.targets()
  run_task('pam_tools::start_nginx_ingress', $no_ingress_targets)

  ##############################
  # Get app details from license
  $license_content = file::read($license_file)
  $kots_slug = pam_tools::get_kots_slug($license_content)
  $kots_app = pam_tools::get_kots_app($license_content)

  #################################################################################
  # Check whether app is already installed because `kots install` is not idempotent
  $status_results = run_task('pam_tools::get_kots_app_status', $targets, {
    'kots_slug' => $kots_slug,
    _catch_errors => true,
  })
  $install_targets = $status_results.filter_set() |$result| {
    # Not ok usually means KOTS isn't installed. We'll get the real error when we
    # try to install.
    !$result.ok or $result.message() == 'not-installed'
  }.targets()

  ##############################################
  # Upload airgap bundle to install targets only
  # (this is redundant if your runner is localhost, but at least it's consistent...)
  if $airgap_bundle {
    $target_bundle = "/tmp/${kots_app}.airgap"
    upload_file($airgap_bundle, $target_bundle, $install_targets)
  } else {
    $target_bundle = undef
  }

  ###########################################
  # Generate and capture target configuration
  $_password = $password =~ Undef ? {
    true  => pam_tools::generate_random_password(16),
    false => $password,
  }

  get_targets($targets).each |$t| {
    if $t.name == 'localhost' {
      # Then we are communicating with a cluster via a local KUBECONFIG.
      # For this case, attempt to look up the target's load balancer ip
      # and generate a self referential nip.io dns name.
      $ip_results = run_task('pam_tools::get_ingress_ip', $t, {
        'timeout'       => 60,
        '_catch_errors' => true,
      }).first()

      $ip = $ip_results.message().empty() ? {
        false   => $ip_results.message(),
        default => '127.0.0.1',
      }
      $nip_hostname = "${kots_app}.${ip}.nip.io"
    } else {
      $nip_hostname = undef
    }

    case $config_file {
      NotUndef: {
        $config_content = file::read($config_file)
      }
      default: {
        $config_content = epp(
          'pam_tools/default-app-config.yaml.epp',
          {
            'kots_app'                      => $kots_app,
            'hostname'                      => pick($hostname, $nip_hostname, $t.host),
            'webhook_hostname'              => $webhook_hostname,
            'password'                      => $_password,
            'allocated_memory_in_gigabytes' => $allocated_memory_in_gigabytes,
            'allocated_cpu'                 => $allocated_cpu,
          }
        )
      }
    }

    set_var($t, 'replicated_config_content', $config_content)
    $config_hash = parseyaml($config_content)
    set_var($t, 'replicated_config_hash', $config_hash)
    $configured_hostname = $config_hash.dig('spec', 'values', 'hostname', 'value')
    if $configured_hostname =~ Undef {
      log::warn(@("EOW"))
        The given config_file '${config_file}' has no hostname set.
        You will probably be unable to connect to the application.
      |- EOW
    }
    set_var($t, 'app_hostname', $configured_hostname)
    $configured_wh_hostname = pick($config_hash.dig('spec', 'values', 'backend_hostname', 'value'), $configured_hostname)
    set_var($t, 'webhook_hostname', $configured_wh_hostname)
    $webhook_port = $configured_wh_hostname != $configured_hostname ? {
      true  => '443',
      false => pick(
        $config_hash.dig('spec', 'values', 'backend_port', 'value'),
        '8000',
      ),
    }
    set_var($t, 'webhook_port', $webhook_port)
  }

  ##################################################################
  # Install the application on targets where it is not yet installed
  $base_install_options = {
    'license_content'      => $license_content,
    'password'             => $_password,
    'airgap_bundle'        => $target_bundle,
    'kots_install_options' => $kots_install_options,
    'pam_variant'          => $pam_variant,
  }
  $install_results = run_task_with('pam_tools::kots_install', $install_targets) |$t| {
    $base_install_options + {
      'config_content' => $t.vars()['replicated_config_content'],
      'hostname'       => $t.vars()['app_hostname'],
    }
  }

  #####################################################
  # Wait for application to report ready on all targets
  if $wait_for_app {
    if $install_results.empty() {
      out::message('All targets already installed.')
    } else {
      get_targets($targets).each |$t| {
        $result = $install_results.find($t.name)
        if $result =~ NotUndef {
          $appname = $result.value()['appname']
          out::message("Installed ${appname} on ${t}")
          out::message("${result.value()['output']}")
        }
      }
    }

    out::message('Waiting for deployment(s) to complete...(this may take several minutes)')

    $wait_results = run_task_with('pam_tools::wait_for_app', $targets) |$t| {
      {
        'kots_slug'    => $kots_slug,
        'app_hostname' => $t.vars()['app_hostname'],
        'app_timeout'  => "${app_timeout}s",
      }
    }
  } else {
    $wait_results = {
      'status' => 'skipped',
    }
  }

  ###########################################################
  # Print basic login information, and password, if generated
  get_targets($targets).each |$t| {
    $app_config = $t.vars()['replicated_config_hash']
    $admin_user = $app_config.dig('spec', 'values', 'root_email', 'value')
    $app_hostname = $t.vars()['app_hostname']
    $wh_hostname = $t.vars()['webhook_hostname']
    $wh_port = $t.vars()['webhook_port']

    out::message("  ** Target: ${t}")
    out::message("  **   ${kots_app} hostname: ${app_hostname}")
    out::message("  **   ${kots_app} webhook: ${wh_hostname}:${wh_port}")
    if $admin_user =~ NotUndef {
      out::message("  **   ${kots_app} root login: ${admin_user}")
    }
    if $password =~ Undef {
      out::message(@("EOM"))
        **   Because no password was given, a random password was generated: ${_password}
        **   You can reset this (for the Kots admin-console) with `kubectl kots reset-password`)
      |- EOM
    }
  }

  $results = {
    'kots_slug'          => $kots_slug,
    'kots_app'           => $kots_app,
    'install_result_set' => $install_results,
    'wait_result_set'    => $wait_results,
  }
  return $results
}
