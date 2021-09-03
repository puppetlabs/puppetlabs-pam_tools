#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Return state of a Kots application.
class GetKotsAppStatus < PAMTaskHelper

  def kots_installed?(namespace)
    test_command = [
      'kubectl',
      'get',
      'pod',
      "--namespace=#{namespace}",
      '--selector=app=kotsadm',
      '--output=name',
    ]
    kotsadm = run_command(test_command).strip
    !kotsadm.empty?
  end

  def task(kots_slug:, kots_namespace:, verbose:, **_kwargs)
    app_list = []
    app_state = 'not-installed'
    kots_installed = kots_installed?(kots_namespace)

    if kots_installed
      output = kots_app_status(kots_namespace)
      app_list = JSON.parse(output)
      status_hash = app_list.find { |s| s['slug'] == kots_slug }
      app_state = status_hash['state'] if !status_hash.nil?
    end

    if verbose
      {
        kots_installed: kots_installed,
        kots_slug: kots_slug,
        app_state: app_state,
        app_status_list: app_list,
      }
    else
      app_state
    end
  end
end

GetKotsAppStatus.run if __FILE__ == $PROGRAM_NAME
