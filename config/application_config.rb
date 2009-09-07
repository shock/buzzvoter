class ApplicationConfig
  
  private

  def merge_key_value(section, key, value)
    case value.class.to_s
    when "Hash"
      section[key] ||= {}
      value.each do |key2, value2|
        merge_key_value(section[key], key2, value2)
      end
    else
      section[key] = value
    end
    section 
  end
    
  public 
  
  def [](key)
    return @global_config[key]
  end
  
  def initialize( application_name="Application" )
    config_filename = File.join(RAILS_ROOT, 'config', 'application.yml')
    @application_name = application_name
    @global_config = YAML::load(IO.read(config_filename))["global"] || {}
    env_config = YAML::load(IO.read(config_filename))[ENV["RAILS_ENV"]]
    env_config.each do |key, value|
      merge_key_value( @global_config, key, value )
    end
  end
  
  def to_s
    output = "#{@application_name} CONFIG:\n"
    output += @global_config.to_yaml
  end
  
  def application_name
    @application_name
  end
  
  def site_url
    url = "#{@global_config[:site][:protocol]}://"
    if @global_config[:site][:host_name]
      url += "#{@global_config[:site][:host_name]}."
    end
    url += "#{@global_config[:site][:domain]}"
    if @global_config[:site][:port]
      url += ":#{@global_config[:site][:port]}"
    end
    url
  end
    
  
end