require "open-uri"
require "net/http"

Error = Class.new(StandardError)

DOWNLOAD_ERRORS = [
  SocketError,
  OpenURI::HTTPError,
  RuntimeError,
  URI::InvalidURIError,
  Error,
]

def download(url, max_size: nil)
  url = URI.encode(URI.decode(url))
  url = URI(url)
  raise Error, "url was invalid" if !url.respond_to?(:open)

  options = {}
  options["User-Agent"] = "MyApp/1.2.3"
  options[:content_length_proc] = ->(size) {
    if max_size && size && size > max_size
      raise Error, "file is too big (max is #{max_size})"
    end
  }

  downloaded_file = url.open(options)

  if downloaded_file.is_a?(StringIO)
    tempfile = Tempfile.new("open-uri", binmode: true)
    IO.copy_stream(downloaded_file, tempfile.path)
    downloaded_file = tempfile
    OpenURI::Meta.init downloaded_file, stringio
  end

  downloaded_file

rescue *DOWNLOAD_ERRORS => error
  raise if error.instance_of?(RuntimeError) && error.message !~ /redirection/
  raise Error, "download failed (#{url}): #{error.message}"
end
