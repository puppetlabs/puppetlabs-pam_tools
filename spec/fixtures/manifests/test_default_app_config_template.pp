# Provides a way to test the parsing of the default Replicated app config template.
class pam_tools::test_default_app_config_template(
  Hash $template_parameters = {}
) {
  $config_yaml = epp('pam_tools/default-app-config.yaml.epp', $template_parameters)
  notify { 'template-output':
    message => $config_yaml,
  }
}
