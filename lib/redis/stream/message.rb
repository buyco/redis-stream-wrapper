require 'pp'
require 'dry-struct'

module Redis
  module Stream
##
# A message type, to be read/written by a Redis Stream.
#
    class Message < ::Dry::Struct::Value
      attribute :stream, ::Dry::Types::Strict::String
      attribute :id, ::Dry::Types::Strict::String.optional.default(nil)
      attribute :payload, ::Dry::Types::Hash.map(Types::Coercible::String, Types::Coercible::String)

      def initialize(stream, payload, id = '*')
        @stream = stream
        @payload = payload
        @id = id
      end

      ##
      # Returns a copy of the current instance, with the id set.
      #
      def copy_with_id(id)
        shallow_copy = self.dup
        shallow_copy.id = id
        shallow_copy
      end
    end
  end
end
