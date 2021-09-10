require 'securerandom'

# Generate a random password of the given length using Ruby's SecureRandom library.
Puppet::Functions.create_function('pam_tools::generate_random_password') do

  # @param length The number of characters to generate.
  # @return The password string.
  dispatch :generate_random_password do
    param 'Integer', :length
    return_type 'String'
  end

  def generate_random_password(length)
    SecureRandom.alphanumeric(length)
  end
end
