defmodule Kane.ConsumerTest do
  use ExUnit.Case

  defmodule TestConsumer do
    use Kane.Consumer

    def handle_messages(messages, %{process: process} = state) do
      send(process, {:handled, messages})
      {:ack, state}
    end

    def filter(%{attributes: attributes}) do
      Map.get(attributes, "category", :none) == "important"
    end
  end

  test "smoke test" do
    {:ok, _consumer} =
      start_supervised({TestConsumer, ["my-subscription", initial_state: %{process: self()}]})

    m1 = %Kane.Message{data: "data1", attributes: %{category: "important"}}
    m2 = %Kane.Message{data: "data2", attributes: %{category: "less-important"}}
    m3 = %Kane.Message{data: "data3", attributes: %{category: "important"}}
    topic = %Kane.Topic{name: "my-topic"}

    {:ok, _} = Kane.Message.publish(m1, topic)
    assert_receive {:handled, [%Kane.Message{data: "data1"}]}

    {:ok, _} = Kane.Message.publish(m2, topic)
    refute_receive {:handled, _}

    {:ok, _} = Kane.Message.publish(m3, topic)
    assert_receive {:handled, [%Kane.Message{data: "data3"}]}
  end
end
