defmodule Conduit.BrokerTest do
  use ExUnit.Case

  defmodule PassThrough do
    use Conduit.Plug

    def call(message, _opts), do: message
  end

  defmodule MyApp.StuffSubscriber do
    use Conduit.Plug

    def call(message, _opts), do: message
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :my_app

    configure do
      exchange "amq.topic"

      queue "my_app.created.stuff", from: ["#.created.stuff"]
    end

    pipeline :incoming do
      plug PassThrough
    end

    pipeline :outgoing do
      plug PassThrough
    end

    incoming Conduit.BrokerTest.MyApp do
      pipe_through :incoming

      sub :stuff, StuffSubscriber, from: "my_app.created.stuff"
    end

    outgoing do
      pipe_through :outgoing

      pub :more_stuff, exchange: "amq.topic", to: "middle_out.created.more_stuff"
    end
  end

  describe ".exchanges" do
    test "returns a list of all exchanges defined" do
      assert Broker.exchanges == [{"amq.topic", []}]
    end
  end

  describe ".queues" do
    test "returns a list of all queues defined" do
      assert Broker.queues == [{"my_app.created.stuff", [from: ["#.created.stuff"]]}]
    end
  end

  describe ".pipelines" do
    test "returns a list of all the pipelines defined" do
      assert Broker.pipelines == [outgoing: Broker.OutgoingPipeline, incoming: Broker.IncomingPipeline]
    end
  end

  describe ".subscribers" do
    test "it returns all the subscribers defined" do
      assert Broker.subscribers == %{
        stuff: {
          Broker.StuffIncoming,
          [from: "my_app.created.stuff"]
        }
      }
    end
  end

  describe ".publishers" do
    test "it returns all the publishers defined" do
      assert Broker.publishers == %{
        more_stuff: {
          Broker.MoreStuffOutgoing,
          [exchange: "amq.topic", to: "middle_out.created.more_stuff"]
        }
      }
    end
  end
end
