require 'rack/request'
require 'mysql_api/controller'

module MySQLAPI
  class Server

    DEFAULT_HEADERS = {
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" => "*",
      "Access-Control-Allow-Headers" => "Content-Type",
      "User-Agent" => "MySQLAPI/#{MySQLAPI::VERSION}"
    }

    def self.call(env)
      # Dispatch the request to the appropriate method on the
      # API controller.
      controller = MySQLAPI::Controller.new(env)

      # get the path
      if env['PATH_INFO'] == "/"
        [404, {}, ["MySQL API doesn't do anything here... try again"]]
      else
        if env['REQUEST_METHOD'] == 'OPTIONS'
          return [200, DEFAULT_HEADERS, ["Nothing to see here."]]
        end

        action = env['PATH_INFO'].gsub(/\A\//, '').split('/').first
        if controller.class.instance_methods(false).include?(action.to_sym)
          begin
            code, headers, body = controller.public_send(action)
            [code, headers.merge(DEFAULT_HEADERS), body]
          rescue Controller::Error => e
            [400, headers.merge(DEFAULT_HEADERS), ["400 Bad Request: #{e.message}"]]
          end
        else
          [404, headers.merge(DEFAULT_HEADERS), ["Invalid API action '#{action}'"]]
        end
      end
    end

  end
end
