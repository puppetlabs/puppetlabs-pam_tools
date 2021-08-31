#! /usr/bin/env ruby

require_relative '../files/kots_task_helper.rb'

# Download Kots application source from the admin console.
class KotsDownload < KotsTaskHelper
  def task(kots_slug:, kots_namespace:, destination: nil, clear_upstream: false, **_kwargs)
    destination ||= "/tmp/#{kots_slug}"

    kots_command = [
      'kubectl-kots',
      'download',
      kots_slug,
      "--namespace=#{kots_namespace}",
      "--dest=#{destination}",
      '--overwrite',
    ]
    output = run_command(kots_command)

    result = {
      command: kots_command.join(' '),
      output: output,
    }

    if clear_upstream
      upstream_manifests = "#{destination}/#{kots_slug}/upstream/*.yaml"
      Dir.glob(upstream_manifests).each { |file| File.delete(file) }
      result[:messages] = "Removed #{upstream_manifests}"
    end

    result
  end
end

KotsDownload.run if __FILE__ == $PROGRAM_NAME
