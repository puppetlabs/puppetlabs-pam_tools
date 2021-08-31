#! /usr/bin/env ruby

require_relative '../files/pam_task_helper.rb'

# Delete a Replicated app's k8s resources.
class DeleteK8sAppResources < PAMTaskHelper

  def task(kots_slug:, kots_namespace:, scaledown_timeout:, **_kwargs)
    api_resources_command = [
      'kubectl',
      'api-resources',
      '--namespaced=true',
      '--verbs=delete',
      '--output=name',
    ]
    resource_types = run_command(api_resources_command).split

    common_options = [
      "--namespace=#{kots_namespace}",
      "--selector=app.kubernetes.io/part-of=#{kots_slug}",
    ]

    # Attempt to scale down before deletion.
    scaled = []
    scale_messages = []
    scaleable_query = [
      'kubectl',
      'get',
      'deployments,replicasets,statefulsets',
      '--output=name',
    ] | common_options
    if !run_command(scaleable_query).empty?
      scale_command = [
        'kubectl',
        'scale',
        'deployments,replicasets,statefulsets',
        '--replicas=0',
      ] + common_options
      scale_output = run_command(scale_command).split("\n")
      scaled, scale_messages = scale_output.partition { |l| l.match(%r{ scaled$}) }

      wait_command = [
        'kubectl',
        'wait',
        'pod',
        '--for=delete',
        "--timeout=#{scaledown_timeout}s",
      ] + common_options
      run_command(wait_command)
    end

    delete_command = [
      'kubectl',
      'delete',
      resource_types.join(','),
      '--wait=true',
    ] + common_options
    delete_output = run_command(delete_command).split("\n")
    deleted, delete_messages = delete_output.partition { |l| l.match(%r{ deleted$}) }

    {
      kots_slug: kots_slug,
      command: delete_command.join(' '),
      messages_from_scale: scale_messages,
      scaled: scaled,
      messages_from_delete: delete_messages,
      deleted: deleted,
    }
  end
end

DeleteK8sAppResources.run if __FILE__ == $PROGRAM_NAME
