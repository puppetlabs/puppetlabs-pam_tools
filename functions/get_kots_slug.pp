# Return the appSlug from a given license file.
#
# Will raise an error if appSlug cannot be found.
#
# @param license
#   A String of the license file content.
# @return
#   The appSlug string from the parsed license spec.
function pam_tools::get_kots_slug(
  String $license,
) {
  $license_hash = parseyaml($license)
  $slug = ($license_hash =~ Hash) ? {
    true  => $license_hash.dig('spec', 'appSlug'),
    false => undef,
  }
  if $slug =~ Undef {
    fail("Unable to locate the Application 'appSlug' value in license content:\n${license}")
  }
  return $slug
}
