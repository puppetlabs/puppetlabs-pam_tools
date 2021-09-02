#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Return state of a Kots application.
class GetKotsAppStatus < PAMTaskHelper

  def task(kots_slug:, kots_namespace:, verbose:, **_kwargs)
    output = kots_app_status(kots_namespace)
    app_list = JSON.parse(output)
    status_hash = app_list.find { |s| s['slug'] == kots_slug }
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
