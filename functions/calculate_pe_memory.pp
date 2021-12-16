# This is a crude memory allocation system that is tuned for the base,
# minimal test memory instance of 4.5GB.
#
# This allows you to spin up Connect on an 8GB test host with the PE
# components squeezed down into:
#
#     pam_tools::calculate_pe_memory(4.5)
#     #
#     # {
#     #   'console_memory'           => 768,
#     #   'postgres_console_memory'  => 256,
#     #   'puppetdb_memory'          => 768,
#     #   'postgres_puppetdb_memory' => 512,
#     #   'orchestrator_memory'      => 768,
#     #   'postgres_orch_memory'     => 256,
#     #   'boltserver_memory'        => 256,
#     #   'puppetserver_memory'      => 1024,
#     # }
#
# Leaving remaining memory for the rest of Connect and system.
#
# Greater memory can be allocated to PE as a whole, but the function simply
# scales linearly, and consequently, this starts to distort the practical
# memory allocation, since, for example, the console is unlikely to need much
# more, whereas postgres might. Still you can bump up PE to 8GB or more quickly
# this way without providing a custom values.yaml.
#
# @param allocated_memory_in_gigabytes
#   The number of gigabytes allocated specifically to PE. In Connect,
#   for example, you could set this to half the system memory. But the
#   minimum it will allocate is 4.5GB.
# @return
#   Hash of memory resource limits in megabytes, keyed by service. This
#   is suitable for settings for the Helm chart or Connect application config.
function pam_tools::calculate_pe_memory(
  Variant[Float,Integer] $allocated_memory_in_gigabytes,
) {
  $memory_floor_in_gigabytes = 4.5
  $allocated_memory_in_megabytes = Integer(max($allocated_memory_in_gigabytes, $memory_floor_in_gigabytes) * 1024)
  $mem_unit = Integer($allocated_memory_in_megabytes / 18)

  $allocation = {
    'console_memory'           => 3 * $mem_unit,
    'postgres_console_memory'  => 1 * $mem_unit,
    'puppetdb_memory'          => 3 * $mem_unit,
    'postgres_puppetdb_memory' => 2 * $mem_unit,
    'orchestrator_memory'      => 3 * $mem_unit,
    'postgres_orch_memory'     => 1 * $mem_unit,
    'boltserver_memory'        => 1 * $mem_unit,
    'puppetserver_memory'      => 4 * $mem_unit,
  }
  return $allocation
}
