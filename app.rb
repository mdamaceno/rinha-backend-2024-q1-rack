require "bundler/setup"
Bundler.require(:default)

class Rinha2024Application
  def call(env)
    request = Rack::Request.new(env)
    path = request.path
    method = request.request_method
    body = request.body.read
    headers = request.env.select { |k, _| k.start_with?("HTTP_") }
    headers = headers.transform_keys { |k| k.sub("HTTP_", "").downcase }
    headers["content-type"] = request.content_type
    headers["content-length"] = body.length.to_s

    body = body.empty? ? {} : body
    status = 200

    require 'pry'; binding.pry

    [status, headers, body]
  end
end
