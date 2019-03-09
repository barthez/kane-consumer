defmodule Kane.Consumer do
  @moduledoc """
  Google PubSub GenServer consumer.

  You need to define your own module using `Kane.Consumer` behaviour. The
  `c:handle_messages/2` definition is mandatory, `c:filter/1` definition is optional.

      defmodule MyPubSubConsumer do
        use Kane.Consumer

        def handle_messages(messages, state) do
          new_state = process(messages, state)
          {:ack, new_state}
        end

        def filter(message) do
          %{attributes: attributes} = message
          attributes["category"] == "my_category"
        end
      end

  To start consumer you need to add it to children list in you Application module:

      defmodule MyApp do

        def start(_type, _args) do
          children = [
            {MyPubSubConsumer, ["my-subscription-name", initial_state: %{}]}
          ]

          Supervisor.start_link(children)
        end
      end

  """

  alias Kane.Message

  @doc """
  Invoked to handle Google PubSub incoming messages.

  Function is called with a list of messages and current internal state of a consumer.
  Expected return value is a tuple with acknowledge action and new internal state.

  When `{:ack, state}` is returned all messages passed to the function will be
  acknowledged. If `{:noack, state}` is returned, messages won't be acknowledged
  and they will appear again after acknowledgment deadline passes.

  Important, if `{:ack, state}` is returned but `handle_messages` takes longer than
  acknowledgment deadline, messages may be delivered twice.
  """
  @callback handle_messages(messages :: [Message.t()], state :: term()) ::
              {:ack, new_state} | {:noack, new_state}
            when new_state: term()

  @doc """
  Filter for incoming messages.

  Function is called on each incoming messages. When it returns `true` message is
  being passed to `c:handle_messages/2`, when `false` messages are acknoledged immediately
  and never processed.

  Default defintion accepts all messages.
  """
  @callback filter(message :: Message.t()) :: boolean

  defmacro __using__(_opts) do
    quote do
      @behaviour Kane.Consumer
      use GenServer

      def start_link(options) do
        GenServer.start_link(__MODULE__, options)
      end

      def init(options) do
        [subscription | options] = options
        subscription = %Kane.Subscription{name: subscription}
        state = Keyword.get(options, :initial_state, %{})

        pull_server =
          DynamicSupervisor.start_child(
            Kane.Consumer.PullSupervisor,
            {Kane.Consumer.PullServer,
             consumer: self(), subscription: subscription, module: __MODULE__}
          )

        case pull_server do
          {:ok, pid} ->
            {:ok, %{sub: subscription, server: pid, consumer_state: state}}

          err ->
            {:stop, :no_pull_server}
        end
      end

      def handle_cast({:messages, messages}, %{consumer_state: consumer_state, sub: sub} = state) do
        {msgs, filtered} = Enum.split_with(messages, &filter/1)

        case handle_messages(msgs, consumer_state) do
          {:ack, new_state} ->
            Kane.Subscription.ack(sub, messages)
            {:noreply, %{state | consumer_state: new_state}}

          {:noack, new_state} ->
            {:noreply, %{state | consumer_state: new_state}}
        end
      end

      @doc """
      Filter messages on arraival

      Messages that are filtered out are autimatically acknowledged.
      """
      def filter(_message) do
        true
      end

      defoverridable filter: 1
    end
  end
end
