#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Start an Nginx IngressController.
class StartNginxIngress < PAMTaskHelper

  def task(version:, provider:, timeout:, **_kwargs)
    source_url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v#{version}/deploy/static/provider/#{provider}/deploy.yaml"
    apply_command = [
      'kubectl',
      'apply',
      "--filename=#{source_url}",
    ]
    apply_output = run_command(apply_command)

    # ingress object creation hard fails until the controller is ready
    wait_command = [
      'kubectl',
      'rollout',
      'status',
      'deployment/ingress-nginx-controller',
      '--namespace=ingress-nginx',
      '--watch',
      "--timeout=#{timeout}s",
    ]
    wait_output = run_command(wait_command)

    {
      command: apply_command.join(' '),
      apply_output: apply_output,
      wait_output: wait_output,
    }
  end
end