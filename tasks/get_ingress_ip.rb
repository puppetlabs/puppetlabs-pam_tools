#! /usr/bin/env ruby

require 'timeout'
require_relative '../files/pam_task_helper.rb'

# Return the ip address of the cluster LoadBalancer service for port 80.
class GetIngressIP < PAMTaskHelper
  def get_load_balancer_for_port(services, port)
    services.find do |s|
      s.dig('spec', 'type') == 'LoadBalancer' &&
        s.dig('spec', 'ports').any? { |p| p['port'] == port }
    end
  end

  def get_load_balancer_ip(port)
    services = get_all_services
    lb = get_load_balancer_for_port(services, port)

    return unless lb

    ingresses = lb.dig('status', 'loadBalancer', 'ingress') || []
    (ingresses.first || {})['ip']
  end

  def task(port:, timeout:, **_kwargs)
    ip = nil

    case timeout
    when 0
      ip = get_load_balancer_ip(port)
    else
      begin
        Timeout.timeout(timeout) do
          while ip.nil?
            ip = get_load_balancer_ip(port)
            break if !ip.nil?
            sleep 1
          end
        end
      rescue Timeout::Error
        raise(PAMTaskHelper::Error.new("Timed out seeking LoadBalancer external ip after #{timeout} seconds.", 'pam_tools/get_ingress_ip/timeout'))
      end
    end

    ip
  end
end

GetIngressIP.run if __FILE__ == $PROGRAM_NAME
