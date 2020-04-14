require 'dry-struct'

# Deprecated but mandatory for "old" projects
module Types
  if Gem.loaded_specs["dry-types"].version >= Gem::Version.create('1.0')
    include Dry::Types()
  else
    include Dry::Types.module
  end
end
