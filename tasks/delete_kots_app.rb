#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Delete a Replicated app from the admin-console.
class DeleteKotsApp < PAMTaskHelper

  def kotsadm_installed?(namespace)
    running = kots_app_status(namespace, exit_on_fail: false).strip
    running !~ %r{Error.*unable to find kotsadm pod}
  end

  def get_all_registered(namespace)
    kots_app_status(namespace).map do |s|
      s['slug']
    end
  end

  def task(kots_slug:, kots_namespace:, force:, **_kwargs)
    if kotsadm_installed?(kots_namespace)
      to_delete = (kots_slug == '*') ?
        get_all_registered(kots_namespace) :
        Array(kots_slug)

      to_delete.each_with_object({}) do |slug, hash|
        delete_command = [
          'kubectl-kots',
          'remove',
          slug,
          "--namespace=#{kots_namespace}",
        ]
        delete_command << '--force' if force
        hash[delete_command.join(' ')] = run_command(delete_command)
      end
    else
      'kotsadm not found, nothing to do'
    end
  end
end

DeleteKotsApp.run if __FILE__ == $PROGRAM_NAME
