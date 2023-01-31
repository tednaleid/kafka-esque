import unittest, test_common
import esquepkg/config


func `==`(value1, value2: EnvironmentConfig): bool =
  value1.name == value2.name


func `==`(value1, value2: EsqueConfig): bool =
  value1.environments == value2.environments

suite "parsing TOML config files":
  test "parsing a simple valid config file with a single environment":

    """
    [env.local]
    broker = "127.0.0.1"
    port = 9092
    """.parseEsqueConfig() === EsqueConfig(environments: @[
      EnvironmentConfig(name: "local", broker: "127.0.0.1", port: 9092)
    ])