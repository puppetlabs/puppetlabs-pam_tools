#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Return true if an lb or nodeport service exists for the given port.
class HasIngressController < PAMTaskHelper
  def lb_port?(spec, port)
    spec['type'] == 'LoadBalancer' && spec['ports'].any? { |p| p['port'] == port }
  end

  def node_port?(spec, port)
    spec['type'] == 'NodePort' && spec['ports'].any? { |p| p['nodePort'] == port }
  end

  def task(**_kwargs)
    services = get_all_services

    services.any? do |service|
      lb_port?(service['spec'], 80) || node_port?(service['spec'], 80)
    end
  end
end

HasIngressController.run if __FILE__ == $PROGRAM_NAME
