require 'mysql_api/version'
require 'mysql2'
require 'json'

module MySQLAPI
  class Controller

    class Error < StandardError; end
    class BadRequest < Error; end

    def initialize(env)
      @env = env
    end

    def query
      # Make sure we have the appropriate params and raise errors if any are
      # missing
      raise BadRequest, "Must provide a `host` parameter" if params['host'].nil?
      raise BadRequest, "Must provide a `username` parameter" if params['username'].nil?
      raise BadRequest, "Must provide a `database` parameter" if params['database'].nil?

      # Connect to the database and raise any connection errors
      begin
        @mysql = Mysql2::Client.new(:host => params['host'], :username => params['username'], :password => params['password'], :database => params['database'])
      rescue Mysql2::Error => e
        return response({:code => "connection-error", :message => e.message}, 403)
      end

      # Execute the queries
      results = params['queries'].each_with_object({}) do |query, hash|
        next unless query['query'].is_a?(String) && query['name'].is_a?(String)
        begin
          if query['values'].is_a?(Array)
            prepare = @mysql.prepare(query['query'])
            result = prepare.execute(*query['values'])
          else
            result = @mysql.query(query['query'])
          end
          hash[query['name']] = query_result_to_hash(result)
        rescue Mysql2::Error => e
          hash[query['name']] = {:status => 'error', :message => e.message}
        end
      end

      response results
    ensure
      @mysql.close rescue nil
    end

    private

    def request
      @request ||= Rack::Request.new(@env)
    end

    def response(content, status = 200, headers = {})
      [status, headers.merge({
        "Content-Type" => "application/json",
      }), [content.to_json]]
    end

    def params
      @params ||= begin
        unless request.content_type == 'application/json'
          raise BadRequest, "The content type for requests should be application/json"
        end

        JSON.parse(request.body.read)
      end
    end

    def query_result_to_hash(results)
      {:status => 'ok', :size => results.size, :cols => results.size == 0 ? [] : results.first.keys, :rows => results.to_a.map(&:values)}
    end

  end
end
