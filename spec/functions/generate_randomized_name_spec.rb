require 'spec_helper'

describe 'pam_tools::generate_randomized_name' do
  let(:generator) { subject }

  it 'returns string with randomized suffix' do
    expect(generator.execute('stem')).to match(%r{stem\.\w{10}})
  end

  it 'returns the given count of random suffix letters' do
    expect(generator.execute('stem', 20)).to match(%r{stem\.\w{20}})
  end

  it 'generates different names for separate calls' do
    a = generator.execute('stem')
    b = generator.execute('stem')
    expect(a).not_to eq(b)
  end
end
