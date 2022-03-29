require 'dry-struct'
require 'redis/stream/wrapper/message'
require 'redis/stream/wrapper/version'
require 'redis/stream/wrapper/exceptions'

class Redis
  module Stream
    class Wrapper

      # Creates a new instance if a Stream.
      #
      # @param redis - An instance of Redis.
      # @param read_timeout_ms - The read timeout granularity.
      #
      def initialize(redis, read_timeout_ms = 1000)
        @redis = redis
        @listening = false
        @read_timeout_ms = read_timeout_ms
      end

      # Deletes the stream.
      #
      # @param stream_name - The name of the stream to delete
      #
      def clear_stream!(stream_name)
        @redis.del(stream_name)
      end

      # Adds a new message to the stream.
      #
      # @param message - The message to add to the stream
      # @return - Message with new id (if default was used)
      #
      def add_message(message)
        copy_message(message, @redis.xadd(message.stream, message.payload, id: message.id))
      end

      # Starts reading stream messages looping
      #
      # @param group - A group to read stream
      # @param consumer_name - A consumer name
      # @param streams - A hash {:stream_name => 'stream_begin_value'}
      # @param opts - A hash of options
      #
      def listen(group, consumer_name, streams, opts = {})
        raise StreamReadError, "Already listening #{streams.keys} stream" if @listening

        @listening = true
        opts[:block] = @read_timeout_ms if opts[:block].nil?
        while @listening
          results = @redis.xreadgroup(group, consumer_name, streams.keys, streams.values, **opts)
          next unless results

          parse_read_response(results).each do |message|
            yield message
          end
        end
      end

      # Starts reading stream messages.
      #
      # @param group - A group to read stream
      # @param consumer_name - A consumer name
      # @param streams - A hash {:stream_name => 'stream_begin_value'}
      # @param opts - A hash of options
      #
      def read(group, consumer_name, streams, opts = {})
        opts[:block] = @read_timeout_ms if opts[:block].nil?
        results = @redis.xreadgroup(group, consumer_name, streams.keys, streams.values, **opts)
        return unless results

        parse_read_response(results).each.map do |message|
          message
        end
      end

      # ACK stream message.
      #
      # @param group - The group that ack
      # @param message - The message to add to the stream
      #
      def ack_message(group, message)
        @redis.xack(message.stream, group, message.id)
      end

      # Delete stream message.
      #
      # @param message - The message to add to the stream
      #
      def delete_message(message)
        @redis.xdel(message.stream, message.id)
      end

      # Create group stream message.
      #
      # @param name - The group name
      # @param stream - The concerned stream
      # @param start - The start stream ($ is only new messages)
      # @param create_default_stream - Bool to create a stream if it does not exist
      #
      def create_group(name, stream, start = '$', create_default_stream = true)
        @redis.xgroup(:create, stream, name, start, mkstream: create_default_stream)
      end

      # Get info about streams / groups and consumers.
      #
      # @param type - The type
      # @param key - The concerned stream / group name
      # @param group - The group name for consumer type
      #
      def info(type, key, group = nil)
        @redis.xinfo(type, key, group)
      end

      # Delete group stream message.
      #
      # @param name - The group name
      # @param stream - The concerned stream
      #
      def delete_group(name, stream)
        @redis.xgroup(:destroy, stream, name)
      end

      # Delete group stream message.
      #
      # @param name - The group name
      # @param stream - The concerned stream
      # @param consumer - The consumer name
      #
      def delete_group_consumer(name, stream, consumer)
        @redis.xgroup(:delconsumer, stream, name, consumer)
      end

      # Stops reading message stream(s)
      #
      def stop_listening
        @listening = false
      end

      private

      def parse_read_response(results)
        results.map do |stream_name, messages|
          messages.map do |id, payload|
            Message.new(
              stream: stream_name,
              payload: parse_payload(payload),
              id: id
            )
          end
        end.flatten.compact
      end

      def parse_payload(payload)
        if payload.is_a? Array
          Hash[payload.each_slice(2).to_a]
        else
          payload
        end
      end

      # Returns a copy of the current instance, with the id set.
      #
      def copy_message(message, new_id)
        message.new(
          id: new_id,
          stream: message.stream,
          payload: message.payload
        )
      end
    end
  end
end
