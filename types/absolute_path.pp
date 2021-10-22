# Pattern ensuring a path begins with a POSIX '/',
# a Windows 'C:\' or '\',
# or a 'puppet:/' module file uri.
type Pam_tools::Absolute_path = Pattern[/^(\/.*|\\|[A-Z]:\\|puppet:\/)/]
