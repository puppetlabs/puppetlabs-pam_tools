# frozen_string_literal: true

require 'json'

# Pulled from: https://raw.githubusercontent.com/puppetlabs/puppetlabs-ruby_task_helper/main/files/task_helper.rb
# rubocop:disable Style/Documentation, Lint/UnusedMethodArgument
class TaskHelper
  attr_reader :debug_statements

  class Error < RuntimeError
    attr_reader :kind, :details, :issue_code

    def initialize(msg, kind, details = nil)
      super(msg)
      @kind = kind
      @issue_code = issue_code
      @details = details || {}
    end

    def to_h
      { 'kind' => kind,
        'msg' => message,
        'details' => details }
    end
  end

  def debug(statement)
    @debug_statements ||= []
    @debug_statements << statement
  end

  def task(params = {})
    msg = 'The task author must implement the `task` method in the task'
    raise TaskHelper::Error.new(msg, 'tasklib/not-implemented')
  end

  # Accepts a Data object and returns a copy with all hash keys
  # symbolized.
  def self.walk_keys(data)
    case data
    when Hash
      data.each_with_object({}) do |(k, v), acc|
        v = walk_keys(v)
        acc[k.to_sym] = v
      end
    when Array
      data.map { |v| walk_keys(v) }
    else
      data
    end
  end

  def self.run
    input = $stdin.read
    params = walk_keys(JSON.parse(input))

    # This method accepts a hash of parameters to run the task, then executes
    # the task. Unhandled errors are caught and turned into an error result.
    # @param [Hash] params A hash of params for the task
    # @return [Hash] The result of the task
    task   = new
    result = task.task(params)

    if result.instance_of?(Hash)
      $stdout.print JSON.generate(result)
    else
      $stdout.print result.to_s
    end
  rescue TaskHelper::Error => e
    $stdout.print({ _error: e.to_h }.to_json)
    exit 1
  rescue StandardError => e
    details = {
      'backtrace' => e.backtrace,
      'debug' => task.debug_statements
    }.compact

    error = TaskHelper::Error.new(e.message, e.class.to_s, details)
    $stdout.print({ _error: error.to_h }.to_json)
    exit 1
  end
end
# rubocop:enable Style/Documentation, Lint/UnusedMethodArgument

require 'open3'

# Extends puppetlabs-ruby_task_helper with some command handling.
class PAMTaskHelper < TaskHelper

  # Kubectl command helpers.
  module KubectlCommands

    # Abstraction containing the identifying elements of a specific deployment
    # or statefulset container's image, along with some helper methods for
    # patching.
    ContainerImage = Struct.new(:namespace, :resource, :container_type, :container_name, :image, keyword_init: true) do

      # @return [String] unique id.
      def id
        "#{namespace},#{resource},#{container_type}:#{container_name},#{image_name}"
      end

      def to_s
        "#{image} #{resource} #{container_type}:#{container_name}"
      end

      # @return [String] everything to the left of the ':' from the image field.
      def image_name
        image.split(':')[0]
      end

      # @return [Boolean] true if what we're given matches the end of the full
      # +image_name+.
      def matches?(comparison)
        image_name.match?(%r{#{comparison}\Z})
      end

      # @param new_version [String] the new version to patch the image to.
      # @return [Hash] of the patch result.
      def patch_version(new_version)
        new_image = image.sub(%r{:.*\Z}, ":#{new_version}")
        patch = %({"spec":{"template":{"spec":{"#{container_type}":[{"name":"#{container_name}","image":"#{new_image}"}]}}}})

        patch_command = [
          'kubectl',
          'patch',
          resource,
          "--namespace=#{namespace}",
          "--patch=#{patch}",
        ]
        patch_result = PAMTaskHelper.run_command(patch_command)

        {
          image: id,
          new_version: new_version,
          command: patch_command.join(' '),
          patch_result: patch_result,
        }
      end
    end

    # @param namespace [String] the namespace to get from.
    # @return [Array] of deployment and statefulset kind/name strings.
    def get_deployments_and_statefulsets(namespace)
      get_command = [
        'kubectl',
        'get',
        'deployment,statefulset',
        "--namespace=#{namespace}",
        '--output=name',
      ]
      run_command(get_command).split("\n")
    end

    # @param resources [Array] of kind/name strings for deployments and statefulsets.
    # @param namespace [String] the namespace of the containers were going to
    # list images for.
    # @return [Array<ContainerImage>] an array of ContainerImage structs.
    def list_container_images(resources, namespace)
      get_container_list = lambda do |resource, container_type|
        list_container_images_command = [
          'kubectl',
          'get',
          resource,
          "--namespace=#{namespace}",
          %(--output=jsonpath={range .spec.template.spec.#{container_type}[*]}{.name},{.image}{"\\n"}{end}),
        ]
        containers = run_command(list_container_images_command).split("\n")
        containers.map do |c|
          container_name, image = c.split(',')
          ContainerImage.new(
            namespace: namespace,
            resource: resource,
            container_type: container_type,
            container_name: container_name,
            image: image,
          )
        end
      end

      resources.map do |r|
        containers = get_container_list.call(r, 'containers')
        containers << get_container_list.call(r, 'initContainers')
      end.flatten
    end

    # @param verb [String] verb recognized by `kubectl api-resources`.
    # @return [Array] of the names of all api-resources supporting the
    #   given +verb+ operation.
    def get_api_resources_for(verb)
      api_resources_command = [
        'kubectl',
        'api-resources',
        '--namespaced=true',
        "--verbs=#{verb}",
        '--output=name',
      ]
      run_command(api_resources_command).split
    end

    # Scale down deployments and statefulsets matching the given
    # selector.
    #
    # @param namespace [String] the k8s namespace.
    # @param selector [String] the k8s selector.
    # @param scaledown_timeout [Integer] seconds to wait for scale down to
    # complete.
    # @return [Hash] of the command, a list of what was scaled and any extra
    # messages output during the scale operation.
    def scale_down(namespace, selector, scaledown_timeout)
      common_options = [
        "--namespace=#{namespace}",
        "--selector=#{selector}",
      ]

      results = {}

      scaleable_query = [
        'kubectl',
        'get',
        'deployments,statefulsets',
        '--output=name',
      ] | common_options

      if run_command(scaleable_query).empty?
        results[:messages_from_scale] = ['No deployments or statefulsets to scale down.']
        results[:scaled] = []
      else
        scale_command = [
          'kubectl',
          'scale',
          'deployments,statefulsets',
          '--replicas=0',
          "--timeout=#{scaledown_timeout}s",
        ] + common_options
        scale_output = run_command(scale_command).split("\n")
        scaled, scale_messages = scale_output.partition { |l| l.match(%r{ scaled$}) }

        results[:scale_command] = scale_command.join(' ')
        results[:messages_from_scale] = scale_messages
        results[:scaled] = scaled
      end

      results
    end

    # Delete all deletable k8s api-resources matching the given
    # selector.
    #
    # @param namespace [String] the k8s namespace.
    # @param selector [String] the k8s selector.
    # @return [Hash] of the command, a list of what was deleted and any extra
    # messages output during the delete operation.
    def delete_resources(namespace, selector)
      resource_types = get_api_resources_for('delete')

      delete_command = [
        'kubectl',
        'delete',
        resource_types.join(','),
        '--wait=true',
        "--namespace=#{namespace}",
        "--selector=#{selector}",
      ]
      delete_output = run_command(delete_command).split("\n")
      deleted, delete_messages = delete_output.partition { |l| l.match(%r{ deleted$}) }

      {
        delete_command: delete_command.join(' '),
        messages_from_delete: delete_messages,
        deleted: deleted,
      }
    end
  end

  include KubectlCommands

  # Kots command helpers.
  module KotsCommands
    def kots_app_status(namespace)
      command = [
        'kubectl-kots',
        'get',
        'apps',
        "--namespace=#{namespace}",
        '--output=json',
      ]
      run_command(command)
    end
  end

  include KotsCommands

  # Execute a command on the system.
  # @return [Boolean] true if successful, false otherwise.
  def test_command(cmd_array)
    _output, status = Open3.capture2e(*cmd_array)
    status.success?
  end

  # Execute a command on the system. Exit on failure.
  # @param cmd_array [Array[String]] array of command and arguments to execute.
  # @param exit_on_fail [Boolean] set false to return output if the command
  # fails rather than exiting.
  # @return [String] Combined stdout and stderr.
  def self.run_command(cmd_array, exit_on_fail = true)
    output, status = Open3.capture2e(*cmd_array)

    if !status.success? && exit_on_fail
      puts "Ran: #{cmd_array.join(' ')}"
      print output
      exit status.exitstatus
    end

    output
  end

  def run_command(cmd_array, exit_on_fail = true)
    PAMTaskHelper.run_command(cmd_array, exit_on_fail)
  end

end
