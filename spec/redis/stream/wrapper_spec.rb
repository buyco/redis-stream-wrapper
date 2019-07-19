require 'spec_helper'
RSpec.describe Redis::Stream::Wrapper do

  let(:stream_name) { "stream-test" }
  let(:payload) { { "foo" => "bar", "woo" => "xoo" } }
  let(:group) { "test-group" }
  let(:message_without_id) { ::Redis::Stream::Wrapper::Message.new(stream: stream_name, payload: payload) }
  let(:wrapper_instance) { described_class.new(redis_client_instance) }
  let(:redis_client_instance) { ::Redis.new(host: ENV.fetch("REDIS_HOST", "localhost"), port: ENV.fetch("REDIS_PORT", 6379), db: ENV.fetch("REDIS_DB", 1)) }

  before(:each) do
    redis_client_instance.flushall
  end

  it "has a version number" do
    expect(Redis::Stream::Wrapper::VERSION).not_to be nil
  end

  it "should be a valid wrapper instance" do
    expect(wrapper_instance).to be_a(::Redis::Stream::Wrapper)
  end

  it "should add a message to stream" do
    message_with_new_id = wrapper_instance.add_message(message_without_id)
    expect(message_with_new_id).to be_a(::Redis::Stream::Wrapper::Message)
    expect(message_with_new_id.stream).to be_equal(message_without_id.stream)
    expect(message_with_new_id.payload).to match(message_without_id.payload)
    expect(message_with_new_id.id).to_not be_equal(message_without_id.id)
  end

  it "should create and delete a group" do
    create_grp_response = wrapper_instance.create_group(group, message_without_id.stream)
    expect(create_grp_response).to match("OK")
    delete_grp_response = wrapper_instance.delete_group(group, message_without_id.stream)
    expect(delete_grp_response).to be_equal(1)
  end

  it "should tell BUSYGROUP on creating an existing group" do
    wrapper_instance.create_group(group, message_without_id.stream)
    expect{wrapper_instance.create_group(group, message_without_id.stream)}.to raise_error(::Redis::CommandError, "BUSYGROUP Consumer Group name already exists")
    wrapper_instance.delete_group(group, message_without_id.stream)
  end

  it "should return 0 on delete when group does not exist" do
    expect{wrapper_instance.delete_group(group, message_without_id.stream)}
      .to raise_error(::Redis::CommandError, /ERR The XGROUP subcommand requires the key to exist/)
  end

  it "should listen messages, ack and delete it" do
    wrapper_instance.create_group(group, message_without_id.stream)
    message = nil
    message_with_id = wrapper_instance.add_message(message_without_id)
    wrapper_instance.listen(group, "test-consumer", { message_without_id.stream => ">"}) do |msg|
      message = msg
      wrapper_instance.stop_listening
    end
    expect(message).to be_a(::Redis::Stream::Wrapper::Message)
    wrapper_instance.ack_message(group, message_with_id)
    wrapper_instance.delete_message(message_with_id)
    wrapper_instance.delete_group(group, message_without_id.stream)
  end

  it "should read messages, ack and delete it" do
    wrapper_instance.create_group(group, message_without_id.stream)
    message_with_id = wrapper_instance.add_message(message_without_id)
    message = wrapper_instance.read(group, "test-consumer", { message_without_id.stream => ">"})

    expect(message.first).to be_a(::Redis::Stream::Wrapper::Message)
    wrapper_instance.ack_message(group, message_with_id)
    wrapper_instance.delete_message(message_with_id)
    wrapper_instance.delete_group(group, message_without_id.stream)
  end
end
