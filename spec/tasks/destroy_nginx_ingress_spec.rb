# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/destroy_nginx_ingress.rb'

describe 'pam_tools::destroy_nginx_ingress' do
  let(:task) { DestroyNginxIngress.new }
  let(:args) { {} }

  it 'runs' do
    expect(task).to(
      receive(:run_command)
        .with(include('kubectl', 'delete', 'namespace/ingress-nginx'))
        .and_return('deleted')
    )

    expect(task.task(args)).to include(output: 'deleted')
  end
end
