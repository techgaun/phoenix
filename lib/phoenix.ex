defmodule Phoenix do
  @moduledoc """
  This is the documentation for the Phoenix project.

  By default, Phoenix applications depend on the following packages:

    * [Ecto](https://hexdocs.pm/ecto) - a language integrated query and
      database wrapper

    * [Phoenix](https://hexdocs.pm/phoenix) - the Phoenix web framework
      (these docs)

    * [Phoenix.js](js) - Phoenix Channels JavaScript client

    * [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub) - a distributed
      pub/sub system with presence support

    * [Phoenix HTML](https://hexdocs.pm/phoenix_html) - conveniences for
      working with HTML in Phoenix

    * [Plug](https://hexdocs.pm/plug) - a specification and conveniences
      for composable modules in between web applications

    * [Gettext](https://hexdocs.pm/gettext) - Internationalization and
      localization through [`gettext`](https://www.gnu.org/software/gettext/)

  There are also optional packages depending on your configuration:

    * [Phoenix PubSub Redis](https://hexdocs.pm/phoenix_pubsub_redis) - use
      Redis to power the Phoenix PubSub system

  """
  use Application

  @doc false
  def start(_type, _args) do
    # Warm up caches
    _ = Phoenix.Template.engines()
    _ = Phoenix.Template.format_encoder("index.html")
    warn_on_missing_json_library()

    # Configure proper system flags from Phoenix only
    if stacktrace_depth = Application.get_env(:phoenix, :stacktrace_depth) do
      :erlang.system_flag(:backtrace_depth, stacktrace_depth)
    end

    # Start the supervision tree
    import Supervisor.Spec

    children = [
      # Code reloading must be serial across all Phoenix apps
      worker(Phoenix.CodeReloader.Server, []),
      supervisor(Phoenix.Transports.LongPoll.Supervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Phoenix.Supervisor)
  end

  # TODO v2: swap Poison default with Jason
  # From there we can ditch explicit config for new projects
  @doc """
  Returns the configured JSON encoding library for Phoenix.

  To customize the JSON library, including the following
  in your `config/config.exs`:

      config :phoenix, :json_library, Jason

  """
  def json_library do
    Application.get_env(:phoenix, :json_library, Poison)
  end

  @doc false
  # Returns the `:init_mode` to pass to `Plug.Builder.compile/3`.
  def plug_init_mode do
    Application.get_env(:phoenix, :plug_init_mode, :compile)
  end

  defp warn_on_missing_json_library do
    module = json_library()
    Code.ensure_loaded?(module) || IO.warn """
    failed to load #{inspect(module)} for Phoenix JSON encoding
    (module #{inspect(module)} is not available).

    Ensure #{inspect(module)} is loaded from your deps in mix.exs, or
    configure an existing encoder in your Mix config using:

        config :phoenix, :json_library, MyJSONLibrary

    """
  end
end
