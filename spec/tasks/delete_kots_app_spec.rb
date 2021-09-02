# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/delete_kots_app.rb'

describe 'pam_tools::delete_kots_app' do
  let(:task) { DeleteKotsApp.new }
  let(:params) do
    {
      kots_slug: 'app',
      kots_namespace: 'default',
      force: false,
    }
  end

  it 'deletes an app' do
    expect(task).to(
      receive(:run_command)
        .with(
          [
            'kubectl-kots',
            'remove',
            'app',
            '--namespace=default',
          ]
        )
        .and_return('deleted')
    )

    expect(task.task(params)).to eq(
      {
        'kubectl-kots remove app --namespace=default' => 'deleted',
      }
    )
  end

  it 'forces delete' do
    params[:force] = true

    expect(task).to(
      receive(:run_command)
        .with(
          [
            'kubectl-kots',
            'remove',
            'app',
            '--namespace=default',
            '--force',
          ]
        )
        .and_return('deleted')
    )

    expect(task.task(params)).to eq(
      {
        'kubectl-kots remove app --namespace=default --force' => 'deleted',
      }
    )
  end

  it 'deletes all apps' do
    params[:kots_slug] = '*'

    apps_hash = [
      {
        'slug' => 'app',
        'state' => 'ready',
      },
      {
        'slug' => 'app2',
        'state' => 'ready',
      },
    ]
    expect(task).to receive(:run_command).with(
      [
        'kubectl-kots',
        'get',
        'apps',
        '--namespace=default',
        '--output=json',
      ]
    ).and_return(apps_hash)

    expect(task).to(
      receive(:run_command)
        .with(include('remove'))
        .and_return('deleted')
        .twice
    )

    expect(task.task(params)).to eq(
      {
        'kubectl-kots remove app --namespace=default' => 'deleted',
        'kubectl-kots remove app2 --namespace=default' => 'deleted',
      }
    )
  end
end
