require 'rack/request'
require 'mysql_api/controller'

module MySQLAPI
  class Server

    def self.call(env)
      # Dispatch the request to the appropriate method on the
      # API controller.
      controller = MySQLAPI::Controller.new(env)

      # get the path
      if env['PATH_INFO'] == "/"
        [404, {}, ["MySQL API doesn't do anything here... try again"]]
      else
        action = env['PATH_INFO'].gsub(/\A\//, '').split('/').first
        if controller.class.instance_methods(false).include?(action.to_sym)
          begin
            controller.public_send(action)
          rescue Controller::Error => e
            [400, {}, ["400 Bad Request: #{e.message}"]]
          end
        else
          [404, {}, ["Invalid API action '#{action}'"]]
        end
      end
    end

  end
end
