defmodule AwesomeDash.Data do
  @div "/"

  def read_value(file_path, filename, parse, default) do
    with file_location <- file_location(file_path, filename),
         true <- File.exists?(file_location),
         {:ok, value} <- File.read(file_location),
         {parsed_value, _} <- parse.(value) do
      parsed_value |> IO.inspect(label: "parsed value for #{file_location}")
    else
      :error -> default
      false -> default
      string when is_binary(string) -> string |> IO.inspect(label: "UNKNOWN IN READ VALUE CATCH")
    end
  end

  def exists?(file_path, filename) do
    file_path
    |> file_location(filename)
    |> File.exists?()
    |> IO.inspect(label: "file exists? #{filename}")
  end

  defp file_location(file_path, filename) do
    List.flatten([file_path, @div, filename]) |> IO.inspect(label: "file_location")
  end
end
