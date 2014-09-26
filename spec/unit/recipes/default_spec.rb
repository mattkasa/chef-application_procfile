require_relative '../../spec_helper.rb'

describe 'fake::default' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'installs foreman chef_gem' do
    expect(chef_run).to install_chef_gem('foreman')
  end

  it 'install monit package' do
    expect(chef_run).to install_package('monit')
  end
end
