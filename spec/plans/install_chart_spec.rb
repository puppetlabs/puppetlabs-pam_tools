# frozen_string_literal: true

require 'spec_helper'

describe 'pam_tools::install_chart' do
  # Include the BoltSpec library functions
  include BoltSpec::Plans

  let(:targets) { ['spec-host'] }
  let(:params) do
    {
      'targets'    => targets,
      'chart_name' => 'test-chart',
      'release'    => 'a-release',
    }
  end

  it 'installs a chart' do
    expect_task('pam_tools::helm_install_chart')
      .with_targets(targets)
      .with_params(
        'chart'      => 'test-chart',
        'release'    => 'a-release',
        'values'     => nil,
        'namespace'  => 'default',
      )
      .always_return('results' => 'installed')

    result = run_plan('pam_tools::install_chart', params)
    expect(result.ok?).to eq(true)
    expect(result.value['repo_results']).to eq('No repository to add.')
    expect(result.value['wait_results']).to match(%r{No part_of selector specified})
  end

  it 'adds a repository then installs a chart' do
    params['repository_uri'] = 'https://a.repo.rspec'
    params['chart_name'] = 'arepo/test-chart'

    expect_task('pam_tools::helm_add_repository')
      .with_targets(targets)
      .with_params(
        'repository_name' => 'arepo',
        'repository_uri'  => 'https://a.repo.rspec',
      )
      .always_return('_output' => 'added arepo')

    expect_task('pam_tools::helm_install_chart')
      .with_targets(targets)
      .with_params(
        'chart'      => 'arepo/test-chart',
        'release'    => 'a-release',
        'values'     => nil,
        'namespace'  => 'default',
      )
      .always_return('results' => 'installed')

    result = run_plan('pam_tools::install_chart', params)
    expect(result.ok?).to eq(true)
    expect(result.value['repo_results']).to be_kind_of(Bolt::ResultSet)
    expect(result.value['wait_results']).to match(%r{No part_of selector specified})
  end

  it 'fails if repository_uri is given but chart_name has no prefix' do
    params['repository_uri'] = 'https://a.repo.rspec'

    result = run_plan('pam_tools::install_chart', params)
    expect(result.ok?).to eq(false)
    expect(result.value.message).to match(%r{Expected to find a repository name})
  end

  it 'installs a chart then waits' do
    params['part_of'] = 'stuff'

    expect_task('pam_tools::helm_install_chart')
    expect_task('pam_tools::wait_for_rollout')
      .with_targets(targets)
      .with_params(
        'selector'  => 'app.kubernetes.io/part-of=stuff',
        'namespace' => 'default',
        'timeout'   => '600s',
      )
      .always_return('_output' => 'running')

    result = run_plan('pam_tools::install_chart', params)
    expect(result.ok?).to eq(true)
    expect(result.value['repo_results']).to eq('No repository to add.')
    expect(result.value['wait_results']).to be_kind_of(Bolt::ResultSet)
  end
end
