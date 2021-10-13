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

    # Any ingress object creation hard fails until the controller is
    # eady, so wait.
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

    # Get the ingress load balancer ip to return to the caller so they
    # have some idea of what to hit to test their app connection.
    lb_ip_lookup_command = [
      'kubectl',
      'get',
      'svc/ingress-nginx-controller',
      '--namespace=ingress-nginx',
      %(--output=jsonpath={.status.loadBalancer.ingress[0].ip}),
    ]
    load_balancer_ip = ''
    counter = 0
    # There may still be a delay before the ip address is readable
    while load_balancer_ip.empty?
      load_balancer_ip = run_command(lb_ip_lookup_command)
      break if !load_balancer_ip.empty?

      counter += 1
      if counter > timeout.to_i
        raise TaskHelper::Error.new(
          "No loadbalancer IP address retrieved after #{timeout} seconds of polling.",
          'pam_tools/ingress-nginx-no-loadbalancer-ip'
        )
      end
      sleep 1
    end

    {
      command: apply_command.join(' '),
      apply_output: apply_output,
      wait_output: wait_output,
      load_balancer_ip: load_balancer_ip,
    }
  end
end

StartNginxIngress.run if __FILE__ == $PROGRAM_NAME
