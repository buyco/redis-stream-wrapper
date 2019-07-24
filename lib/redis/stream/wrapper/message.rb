require 'dry-struct'
require_relative 'types'

class Redis
  module Stream
    class Wrapper
      class Message < ::Dry::Struct::Value
        # Types = ::Dry.Types(default: :nominal)
        attribute :stream, ::Types::Coercible::String
        attribute :id, ::Types::Coercible::String.optional.default('*', shared: true)
        attribute :payload, ::Types::Hash.map(::Types::Coercible::String, ::Types::Coercible::String)
      end
    end
  end
end
