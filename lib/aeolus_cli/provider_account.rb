require 'aeolus_cli/common_cli'
require 'aeolus_cli/model/provider_account'

class AeolusCli::ProviderAccount < AeolusCli::CommonCli

  desc "list", "list provider accounts"
  # TODO maybe an optional variable for provider_type
  def list
    accts = AeolusCli::Model::ProviderAccount.all.map! do |acct|
      full = AeolusCli::Model::ProviderAccount.find(acct.id)
      full.print_quota = full.quota.maximum_running_instances
      full.print_username = full.credentials.username
      full
    end
    print_table({:name => "Name",
                 :provider => "Provider",
                 :print_username => "Username",
                 :print_quota => "Quota"},
                accts)
  end

  desc "add PROVIDER_ACCOUNT_LABEL", "Add a provider account"
  method_option :provider_name, :type => :string, :required => true,
    :aliases => "-n", :desc => "(already existing) provider name"
  method_option :credentials_file, :type => :string, :required => true,
    :desc => "path to credentials xml file"
  method_option :quota, :type => :string, :aliases => "-q",
    :default => "unlimited", :desc => "maximum running instances"
  def add(label)
    credentials = credentials_from_file(options[:credentials_file])
    provider = AeolusCli::Model::Provider.all.find {|p| p.name == options[:provider_name]}
    unless provider
      self.shell.say "ERROR: The provider '#{options[:provider_name]}' does not exist"
      exit(1)
    end

    pa = AeolusCli::Model::ProviderAccount.new(
           :label => label,
           :provider => {:id => provider.id},
           :credentials => credentials,
           :quota => {:maxiumum_running_instances => options[:quota]})

    if !pa.save
      self.shell.say "ERROR:  Conductor was unable to save the provider account"
      self.shell.say pa.errors.full_messages
      exit(1)
    else
      self.shell.say "Provider account #{label} added with id #{pa.id}"
    end
  end

  protected
  def credentials_from_file(file)
    begin
      h = Hash.from_xml(File.open(file).read())['credentials']
    rescue Errno::ENOENT => e
      self.shell.say "ERROR: #{e.message}"
      exit(1)
    rescue REXML::ParseException => e
      self.shell.say "ERROR: Unable to parse #{file}"
      exit(1)
    end

    unless h
      self.shell.say "ERROR: Root element of #{file} must be 'credentials'"
      exit(1)
    end

    h
  end
end
