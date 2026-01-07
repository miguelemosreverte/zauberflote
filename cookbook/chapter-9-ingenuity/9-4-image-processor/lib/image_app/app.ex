defmodule ImageApp.Application do
  use Shared.App.Runner, port: 4904
end

defmodule ImageApp.Router do
  use Shared.App

  resource "/process" do
    post args: [file: :file] do
      # Note: 'file' is a %Plug.Upload{} struct
      temp_path = file.path
      target_path = "uploads/processed_#{Path.basename(temp_path)}"

      # Ensure uploads directory exists
      File.mkdir_p!("uploads")

      # Use ImageMagick to convert to grayscale
      # Attempting 'magick' (v7) or 'convert' (v6)
      cmd = System.find_executable("magick") || System.find_executable("convert")

      if cmd do
        case System.cmd(cmd, [temp_path, "-colorspace", "Gray", target_path], stderr_to_stdout: true) do
          {_, 0} ->
            # Success: Read the binary and return as Base64
            binary = File.read!(target_path)
            base64 = Base.encode64(binary)
            # Clean up
            File.rm(target_path)
            %{preview: "data:image/png;base64,#{base64}"}

          _ ->
            # Fallback if ImageMagick failed: Return original
            binary = File.read!(temp_path)
            base64 = Base.encode64(binary)
            %{preview: "data:image/png;base64,#{base64}", note: "Grayscale conversion failed"}
        end
      else
        # ImageMagick not installed: Return original image
        binary = File.read!(temp_path)
        base64 = Base.encode64(binary)
        %{preview: "data:image/png;base64,#{base64}", note: "ImageMagick not installed - returning original"}
      end
    end
  end
end
