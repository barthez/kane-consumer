defmodule KaneConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :kane_consumer,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Kane.Consumer",
      source_url: "https://github.com/barthez/kane-consumer",
      homepage_url: "https://github.com/barthez/kane-consumer",
      docs: [
        main: "Kane.Consumer",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:kane, :logger],
      mod: {Kane.Consumer.Application, []}
    ]
  end

  defp deps do
    [
      {:kane, "~> 0.7.0-beta"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
