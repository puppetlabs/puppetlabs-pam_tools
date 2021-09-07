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
  def run_command(cmd_array, exit_on_fail = true)
    output, status = Open3.capture2e(*cmd_array)

    if !status.success? && exit_on_fail
      puts "Ran: #{cmd_array.join(' ')}"
      print output
      exit status.exitstatus
    end

    output
  end

end
