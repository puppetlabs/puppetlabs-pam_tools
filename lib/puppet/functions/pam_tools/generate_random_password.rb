require 'securerandom'

# Generate a random password of the given length using Ruby's SecureRandom library.
#
# @param length [Integer] number of characters to generate.
# @return [String] password.
Puppet::Functions.create_function('pam_tools::generate_random_password') do
  dispatch :generate_random_password do
    param 'Integer', :length
    return_type 'String'
  end

  def generate_random_password(length)
    SecureRandom.alphanumeric(length)
  end
end
