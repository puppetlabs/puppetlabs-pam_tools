#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Return true if an lb or nodeport service or pod with hostPort exists for the given port.
class HasIngressController < PAMTaskHelper
  def lb_port?(spec, port)
    spec['type'] == 'LoadBalancer' && spec['ports'].any? { |p| p['port'] == port }
  end

  def node_port?(spec, port)
    spec['type'] == 'NodePort' && spec['ports'].any? { |p| p['nodePort'] == port }
  end

  def host_port?(pod, port)
    containers = pod['spec']['containers']
    containers.any? do |c|
      (c['ports'] || []).any? { |p| p['hostPort'] == port }
    end
  end

  def task(**_kwargs)
    services = get_resources('service')

    service_ingress = services.any? do |service|
      lb_port?(service['spec'], 80) || node_port?(service['spec'], 80)
    end

    pod_ingress = false
    if !service_ingress
      pods = get_resources('pod')
      pod_ingress = pods.any? { |pod| host_port?(pod, 80) }
    end

    service_ingress || pod_ingress
  end
end

HasIngressController.run if __FILE__ == $PROGRAM_NAME
