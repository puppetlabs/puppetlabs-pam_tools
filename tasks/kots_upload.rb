#! /usr/bin/env ruby

require_relative '../files/kots_task_helper.rb'

class KotsUpload < KotsTaskHelper
  def task(kots_slug:, kots_namespace:, source: nil, deploy: false, skip_preflights: false, **kwargs)
    source ||= "/tmp/#{kots_slug}"

    kots_command = [
      'kubectl-kots',
      'upload',
      source,
      "--namespace=#{kots_namespace}",
      "--slug=#{kots_slug}",
    ]
    kots_command << '--deploy' if deploy
    kots_command << '--skip-preflights' if skip_preflights
    output = run_command(kots_command)

    {
      command: kots_command.join(' '),
      output: output,
    }
  end
end

KotsUpload.run if __FILE__ == $PROGRAM_NAME
