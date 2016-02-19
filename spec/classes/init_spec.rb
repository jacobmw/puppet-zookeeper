require 'spec_helper'

describe 'zookeeper', :type => :class do
  let(:user) { 'zookeeper' }
  let(:group) { 'zookeeper' }

  let(:facts) {{
    :operatingsystem => 'Debian',
    :osfamily        => 'Debian',
    :lsbdistcodename => 'wheezy',
    :ipaddress       => '192.168.1.1',
  }}

  it { should contain_class('zookeeper::config') }
  it { should contain_class('zookeeper::install') }
  it { should contain_class('zookeeper::service') }
  it { should compile.with_all_deps }


  context 'allow installing multiple packages' do
    let(:params) {{
      :packages => [ 'zookeeper', 'zookeeper-bin' ],
    }}

    it { should contain_package('zookeeper').with({:ensure => 'present'}) }
    it { should contain_package('zookeeper-bin').with({:ensure => 'present'}) }
    it { should contain_service('zookeeper').with({:ensure => 'running'}) }
    # datastore exec is not included by default
    it { should_not contain_exec('initialize_datastore') }

    it { should contain_user('zookeeper').with({:ensure => 'present'}) }
    it { should contain_group('zookeeper').with({:ensure => 'present'}) }
  end

  context 'Cloudera packaging' do
    let(:user) { 'zookeeper' }
    let(:group) { 'zookeeper' }

    let(:params) { {
      :packages             => ['zookeeper','zookeeper-server'],
      :service_name         => 'zookeeper-server',
      :initialize_datastore => true
    } }

    it { should contain_package('zookeeper').with({:ensure => 'present'}) }
    it { should contain_package('zookeeper-server').with({:ensure => 'present'}) }
    it { should contain_service('zookeeper-server').with({:ensure => 'running'})  }
    it { should contain_exec('initialize_datastore') }
  end

  context 'setting minSessionTimeout' do
    let(:params) {{
      :min_session_timeout => 3000
    }}

    it { should contain_file(
      '/etc/zookeeper/conf/zoo.cfg'
    ).with_content(/minSessionTimeout=3000/) }
  end

  context 'setting maxSessionTimeout' do
    let(:params) {{
      :max_session_timeout => 60000
    }}

    it { should contain_file(
      '/etc/zookeeper/conf/zoo.cfg'
    ).with_content(/maxSessionTimeout=60000/) }
  end

  context 'disable service management' do
    let(:user) { 'zookeeper' }
    let(:group) { 'zookeeper' }

    let(:params) { {
      :manage_service => false,
    } }

    it { should contain_package('zookeeper').with({:ensure => 'present'}) }
    it { should_not contain_service('zookeeper').with({:ensure => 'running'}) }
    it { should_not contain_class('zookeeper::service') }
  end

  context 'use Cloudera RPM repo' do
    let(:facts) {{
      :ipaddress => '192.168.1.1',
      :osfamily => 'RedHat',
      :operatingsystemmajrelease => '7',
      :hardwaremodel => 'x86_64',
    }}

    let(:params) {{
      :repo => 'cloudera',
      :cdhver => '5',
    }}

    it { should contain_class('zookeeper::repo') }
    it { should contain_yumrepo('cloudera-cdh5') }

    context 'custom RPM repo' do
      let(:params) {{
        :repo => {
          'name'  => 'myrepo',
          'url'   => 'http://repo.url',
          'descr' => 'custom repo',
        },
        :cdhver => '5',
      }}
      it { should contain_yumrepo('myrepo').with({:baseurl => 'http://repo.url'}) }
    end
  end

  context 'service provider' do
    let(:user) { 'zookeeper' }
    let(:group) { 'zookeeper' }

    context 'do not set provider by default' do
      it { should contain_package('zookeeper').with({:ensure => 'present'}) }
      it { should contain_service('zookeeper').with({
        :ensure => 'running',
        :provider => nil,
      })}
    end

    context 'autodetect provider on RedHat 7' do
      let(:facts) {{
        :ipaddress => '192.168.1.1',
        :osfamily => 'RedHat',
        :operatingsystemmajrelease => '7',
      }}
      it { should contain_package('zookeeper').with({:ensure => 'present'}) }
      it { should contain_package('zookeeper-server').with({:ensure => 'present'}) }
      it { should contain_service('zookeeper-server').with({
        :ensure => 'running',
        :provider => 'systemd',
      })}
    end

    it { should contain_class('zookeeper::service') }
  end

  context 'upstart is used on Ubuntu' do
    let(:facts) {{
      :ipaddress => '192.168.1.1',
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :majdistrelease => '14.04',
    }}

    it { should contain_package('zookeeper').with({:ensure => 'present'}) }
    it { should contain_package('zookeeperd').with({:ensure => 'present'}) }
    it { should contain_service('zookeeper').with({
      :ensure => 'running',
      :provider => 'upstart',
    })}
  end


  context 'automatically generate zookeeper ID' do
    let(:facts) {{
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :majdistrelease => '14.04',
      :ipaddress => '192.168.1.3',
      :id_generator => 'mod'
    }}

    #Puppet::Util::Log.level = :debug
    #Puppet::Util::Log.newdestination(:console)

    let(:params) {{
      :client_ip => '192.168.1.3',
    }}

    it { should contain_class('zookeeper::config') }

    # mod strategy: '192.168.1.1' -> 108
    it { should contain_file('/etc/zookeeper/conf/myid').with({
      'ensure'  => 'file',
      'owner'   => user,
      'group'   => group,
    }).with_content(110) }

  end

end
