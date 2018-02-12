defmodule EventStore.Supervisor do
  @moduledoc false

  use Supervisor

  alias EventStore.{Config, Registration}

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(config) do
    postgrex_opts = Config.postgrex_opts(config)
    subscription_postgrex_config = Config.subscription_postgrex_opts(config)

    children =
      [
        {Postgrex, postgrex_opts},
        {Postgrex, subscription_postgrex_config},
        Supervisor.child_spec(
          {Registry, keys: :unique, name: EventStore.Subscriptions.Subscription},
          id: EventStore.Subscriptions.Subscription
        ),
        {EventStore.AdvisoryLocks, []},
        {EventStore.Subscriptions.Supervisor, [EventStore.Subscriptions.Postgrex]},
        {EventStore.Notifications.Supervisor, config}
      ] ++ Registration.child_spec()

    Supervisor.init(children, strategy: :one_for_one)
  end
end
