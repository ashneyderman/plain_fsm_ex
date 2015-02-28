defmodule PlainFsmEx.Mixfile do
  use Mix.Project

  def project do
    [app: :plain_fsm_ex,
     version: "1.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:plain_fsm, git: "https://github.com/uwiger/plain_fsm.git", 
                   ref: "30a9b20c733820d74b01830b59d4bd041cf10f05"}
    ]
  end
end
