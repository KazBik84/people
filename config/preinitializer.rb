ENV["RAILS_ENV"] ||= 'development'
require 'active_support/core_ext'
require 'konf'

AppConfig = Konf.new(
  %w{
    ../config.yml
    ../sec_config.yml.sample
  }.inject({}) do |config_hash, file_path|
    config_hash.deep_merge(
      begin
        YAML.load(
          ERB.new(
            File.read(
              File.expand_path(file_path, __FILE__)
            )
          ).result
        ).fetch(ENV['RAILS_ENV']) { {} }
      rescue Errno::ENOENT
        {}
      end
    )
  end
)
