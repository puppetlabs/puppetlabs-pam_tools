# frozen_string_literal: true

require 'yaml'

module PAMTools
  module SpecHelper
    def project_root
      File.expand_path(File.join(__dir__, '..', '..'))
    end

    def fixtures_path
      File.expand_path(File.join(project_root, 'spec', 'fixtures'))
    end

    def fixtures_license_path
      File.join(fixtures_path, 'licenses')
    end

    def license(appname_string)
      File.read(File.join(fixtures_license_path, "test-#{appname_string}-license.yaml"))
    end

    def license_hash(appname_string)
      YAML.safe_load(license(appname_string))
    end
  end
end
