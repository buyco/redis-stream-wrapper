require 'dry-struct'

module Redis
  module Stream
    module Wrapper
      class Message < ::Dry::Struct::Value
        attribute :stream, ::Dry::Types::Strict::String
        attribute :id, ::Dry::Types::Strict::String
        attribute :payload, ::Dry::Types::Hash.map(::Dry::Types::Coercible::String, ::Dry::Types::Coercible::String)

        def initialize(stream, payload, id = '*')
          @stream = stream
          @payload = payload
          @id = id
        end
      end
    end
  end
end
