require 'spec_helper'

describe 'pam_tools::calculate_pe_memory' do
  let(:allocated_4_point_5) do
    {
      'console_memory'           => 768,
      'postgres_console_memory'  => 256,
      'puppetdb_memory'          => 768,
      'postgres_puppetdb_memory' => 512,
      'orchestrator_memory'      => 768,
      'postgres_orch_memory'     => 256,
      'boltserver_memory'        => 256,
      'puppetserver_memory'      => 1024,
    }
  end

  it 'returns memory allocation' do
    is_expected.to run.with_params(9).and_return(
      allocated_4_point_5.transform_values { |v| v * 2 }
    )
  end

  it 'returns a floor' do
    is_expected.to run.with_params(4.5).and_return(allocated_4_point_5)
    is_expected.to run.with_params(2).and_return(allocated_4_point_5)
  end
end
