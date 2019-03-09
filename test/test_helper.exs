ExUnit.start()

defmodule TestToken do
  def for_scope(_scope) do
    {:ok, %Goth.Token{token: "token", type: "Bearer", expires: :os.system_time() + 3600}}
  end
end

Kane.Topic.delete("my-topic")
Kane.Subscription.delete("my-subscription")
{:ok, topic} = Kane.Topic.create("my-topic")
sub = %Kane.Subscription{name: "my-subscription", topic: topic}
Kane.Subscription.create(sub)
