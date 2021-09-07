# frozen_string_literal: true

require 'spec_helper'

describe 'pam_tools::teardown' do
  # Include the BoltSpec library functions
  include BoltSpec::Plans

  let(:targets) { ['spec-host'] }
  let(:params) do
    {
      'targets'   => targets,
      'kots_slug' => 'app',
    }
  end

  before(:each) do
    expect_task('pam_tools::delete_k8s_app_resources')
      .with_targets(targets)
      .with_params(
        'kots_slug'         => 'app',
        'kots_namespace'    => 'default',
        'scaledown_timeout' => 300,
      )
  end

  it 'deletes app' do
    result = run_plan('pam_tools::teardown', params)

    expect(result.ok?).to eq(true)
    expect(result.value['kots_slug']).to eq('app')
    expect(result.value['destroy_app_result_set']).to be_kind_of(Bolt::ResultSet)
    expect(result.value['remove_app_from_console_result_set']).to eq('not-done')
    expect(result.value['delete_kotsadm_result_set']).to eq('not-done')
  end

  it 'deletes and removes app' do
    params['remove_app_from_console'] = true
    expect_task('pam_tools::delete_kots_app')
      .with_targets(targets)
      .with_params(
        'kots_slug'      => 'app',
        'kots_namespace' => 'default',
        'force'          => true,
      )

    result = run_plan('pam_tools::teardown', params)

    expect(result.ok?).to eq(true)
    expect(result.value['kots_slug']).to eq('app')
    expect(result.value['destroy_app_result_set']).to be_kind_of(Bolt::ResultSet)
    expect(result.value['remove_app_from_console_result_set']).to be_kind_of(Bolt::ResultSet)
    expect(result.value['delete_kotsadm_result_set']).to eq('not-done')
  end

  it 'deletes app and deletes kotsadm' do
    params['delete_kotsadm'] = true
    expect_task('pam_tools::delete_kotsadm')
      .with_targets(targets)
      .with_params(
        'kots_namespace'    => 'default',
        'scaledown_timeout' => 300,
      )

    result = run_plan('pam_tools::teardown', params)

    expect(result.ok?).to eq(true)
    expect(result.value['kots_slug']).to eq('app')
    expect(result.value['destroy_app_result_set']).to be_kind_of(Bolt::ResultSet)
    expect(result.value['remove_app_from_console_result_set']).to eq('not-done')
    expect(result.value['delete_kotsadm_result_set']).to be_kind_of(Bolt::ResultSet)
  end
end
