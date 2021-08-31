#! /usr/bin/env ruby

require_relative '../files/kots_task_helper.rb'

class GetKotsAppStatus < KotsTaskHelper

  def task(kots_slug:, kots_namespace:, verbose:, **kwargs)
    kots_command = [
      'kubectl-kots',
      'get',
      'apps',
      "--namespace=#{kots_namespace}",
      '--output=json',
    ]
    output = run_command(kots_command)
    app_list = JSON.parse(output)
    status_hash = app_list.select { |s| s['slug'] == kots_slug }.first
    app_state = status_hash.nil? ? 'not-installed' : status_hash['state']

    if verbose
      {
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
