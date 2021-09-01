#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Tear down the Nginx IngressController.
class DestroyNginxIngress < PAMTaskHelper

  def task(**_kwargs)
    delete_command = [
      'kubectl',
      'delete',
      'namespace/ingress-nginx',
      'ValidatingWebhookConfiguration/ingress-nginx-admission',
      '--ignore-not-found',
    ]
    output = run_command(delete_command)

    {
      command: delete_command,
      output: output,
    }
  end
end
