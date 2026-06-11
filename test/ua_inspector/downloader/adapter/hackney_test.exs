defmodule UAInspector.Downloader.Adapter.HackneyTest do
  use ExUnit.Case, async: true

  alias UAInspector.Downloader.Adapter.Hackney

  test "errors returned from adapter" do
    assert {:error, :nxdomain} = Hackney.read_remote("invalid")
  end

  test "reads HTTP 200 response bodies" do
    document_root = temporary_document_root()
    File.write!(Path.join(document_root, "response.txt"), "ok")

    {:ok, httpd_pid} = start_httpd(document_root, "success")

    on_exit(fn ->
      :inets.stop(:httpd, httpd_pid)
      File.rm_rf!(document_root)
    end)

    location = "http://localhost:#{:httpd.info(httpd_pid)[:port]}/response.txt"

    assert {:ok, "ok"} = Hackney.read_remote(location)
  end

  test "requires HTTP 200 responses for success" do
    {:ok, httpd_pid} = start_httpd(__DIR__, "not_found")

    on_exit(fn -> :inets.stop(:httpd, httpd_pid) end)

    location = "http://localhost:#{:httpd.info(httpd_pid)[:port]}/--does-not-exist--"

    assert {:error, {:status, 404, ^location}} = Hackney.read_remote(location)
  end

  defp start_httpd(document_root, name) do
    server_name =
      "ua_inspector_hackney_#{name}_#{System.unique_integer([:positive])}"
      |> String.to_charlist()

    :inets.start(:httpd,
      port: 0,
      server_name: server_name,
      server_root: String.to_charlist(document_root),
      document_root: String.to_charlist(document_root)
    )
  end

  defp temporary_document_root do
    path =
      System.tmp_dir!()
      |> Path.join("ua_inspector_hackney_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(path)
    path
  end
end
