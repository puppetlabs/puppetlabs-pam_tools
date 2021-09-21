# Given a stem and optional character count, return a name with a random extension.
# Useful for generating randomized temp directories, for example.
#
# Seeding is not tied to host(s), and should be random for each call.
#
# @example
#   $r = pam_tools::generate_randomized_name('test', 12)
#   notice($r)
#   # Notice: Scope(Class[main]): test.x5gghIjk32ld
#
# @param stem
#   The start of the string.
# @param count
#   Number of randomized characters to add as a suffix.
function pam_tools::generate_randomized_name(
  String $stem,
  Integer $count = 10,
) {
  # Simple way to get a random string of +count+ characters...
  $r = pam_tools::generate_random_password($count)
  return "${stem}.${r}"
}
