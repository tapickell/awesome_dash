defmodule AwesomeDash.Data do
  def read_value(file_path, filename, parse, default) do
    with file_location <- file_location(file_path, filename),
         true <- File.exists?(file_location),
         {:ok, value} <- File.read(file_location),
         {parsed_value, _} <- parse.(value) do
      parsed_value
    else
      :error -> default
    end
  end

  def exists?(file_path, filename) do
    file_path
    |> file_location(filename)
    |> File.exists?()
  end

  defp file_location(file_path, filename) do
    List.flatten([file_path, filename])
  end
end
