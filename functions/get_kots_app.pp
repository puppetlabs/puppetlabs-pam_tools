# Return the application name based on kots_slug and entitlement from the given
# license file.
#
# @param license
#   A String of the license file content.
# @return
#   The associated application name (which may differ from kots_slug).
# @raise PuppetError
#   If appSlug cannot be found in the license.
function pam_tools::get_kots_app(
  String $license,
) {
  $license_hash = parseyaml($license)
  $connect_entitlement = $license_hash.dig('spec', 'entitlements', 'connect_entitlement', 'value')
  $cd4pe_entitlement = $license_hash.dig('spec', 'entitlements', 'cd_entitlement', 'value')

  ($connect_entitlement and !$cd4pe_entitlement) ? {
    true    => 'connect',
    default => pam_tools::get_kots_slug($license),
  }
}
