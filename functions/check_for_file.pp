# Raises an error if the given file path does not exist or cannot be read.
#
# If path does not exist or is not readable.
#
# @param filetype
#   Type of file to display in error messages.
# @param path
#   To the file.
# @param fail_empty_path
#   If true, fail if no +path+ parameter is given.
# @return
#   The +path+ if found, or undef if no path given.
function pam_tools::check_for_file(
  String $filetype,
  Optional[String] $path = undef,
  Boolean $fail_empty_path = true,
) {
  if $path !~ Undef {
    if !file::exists($path) {
      fail("${filetype} ${path} could not be found")
    } elsif !file::readable($path) {
      fail("${filetype} ${path} could not be read")
    }
  } elsif $fail_empty_path {
    fail("No path to '${filetype}' file given.")
  }
  return $path
}
