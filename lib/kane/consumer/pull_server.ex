defmodule Kane.Consumer.PullServer do
  @moduledoc false

  use GenServer
  require Logger

  @doc false
  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @doc false
  def init(options) do
    state = Enum.into(options, %{})

    {:ok, state, {:continue, :pull}}
  end

  @doc false
  def child_spec(options) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [options]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def handle_continue(:pull, state) do
    %{consumer: consumer, subscription: sub, module: module} = state

    case Kane.Subscription.pull(sub, return_immediately: false) do
      {:ok, []} ->
        Logger.info("PullServer: No messages")
        {:noreply, state, {:continue, :pull}}

      {:ok, messages} ->
        Logger.info("PullServer: Got #{length(messages)} messages")
        {matching, redundant} = Enum.split_with(messages, &module.filter/1)

        if length(matching) > 0 do
          GenServer.cast(consumer, {:messages, matching})
        end

        if length(redundant) > 0 do
          GenServer.cast(self(), {:ack, redundant})
        end

        {:noreply, state, {:continue, :pull}}

      error ->
        Logger.info("PullServer: Error #{inspect(error)}")
        {:stop, error, state}
    end
  end
end
