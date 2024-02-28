require "bundler/setup"
Bundler.require(:default)

class ConnectionManager
  @pool = nil

  class << self
    def connection_pool
      @pool || create_pool
    end

    private

    def create_pool
      @pool = ConnectionPool.new(size: 30, timeout: 30) do
        PG.connect(ENV["DATABASE_URL"])
      end
    end
  end
end

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

    ConnectionManager.connection_pool.with do |conn|
      require 'pry'; binding.pry
    end

    [status, headers, body]
  end
end
