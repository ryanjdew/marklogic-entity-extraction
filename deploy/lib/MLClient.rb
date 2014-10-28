###############################################################################
# Copyright 2012 MarkLogic Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
begin
require 'io/console'
rescue LoadError
end

require 'uri'

class MLClient
  def initialize(options)
    @ml_username = options[:user_name]
    @ml_password = options[:password]
    @logger = options[:logger] || logger
    @request = {}
  end

  def MLClient.logger()
    @@logger ||= Logger.new(STDOUT)
  end

  def MLClient.logger=(logger)
    @@logger = logger
  end

  def logger()
    @logger
  end

  def get_http
    if (!@http)
      @http = Roxy::Http.new({
        :logger => logger
      })
    end
    @http
  end

  def build_request_params(url, verb)
    uri = URI.parse url

    if (!@request[verb])
      @request[verb] = Net::HTTP.const_get(verb.capitalize).new(uri.request_uri)
      @request[verb].add_field 'Connection', 'keep-alive'
      @request[verb].add_field 'Keep-Alive', '30'
      @request[verb].add_field 'User-Agent', 'Roxy'
      @request[verb].add_field 'content-type', 'text/plain'
    else
      @request[verb].set_path uri.request_uri
    end
    request_params = {
      :request => @request[verb],
      :server => uri.host,
      :port => uri.port,
      :protocol => uri.scheme,
      :user_name => @ml_username,
      :password => @ml_password,
      :logger => logger
    }
  end

  # Parameters:
  # - auth_method: this can be used to specify whether to use digest or basic authentication to respond to a 401
  #   The default behavior is to digest.
  def go(url, verb, headers = {}, params = nil, body = nil, auth_method = nil)
    password_prompt
    request_params = build_request_params(url, verb)
    # configure headers
    headers.each do |k, v|
      request_params[:request][k] = v
    end

    raise ExitException.new("Don't combine params and body. One or the other please") if (params && body)

    if (params)
      request_params[:request].set_form_data(params)
    end

    if (body)
      request_params[:request].body = body
    end

    if (auth_method)
      request_params[:auth_method] = auth_method
    end

    response = get_http.request request_params
    response.value
    response
  end

  def url_encode(str)
    return str.gsub(/[^-_.a-zA-Z0-9]+/) { |s|
      s.unpack('C*').collect { |i| "%%%02X" % i }.join
    }
  end

  def prompt(*args)
    print(*args)
    gets.strip
  end

  def password_prompt
    if (@ml_password == "") then
      if STDIN.respond_to?(:noecho)
      print "Password for admin user: "
      @ml_password = STDIN.noecho(&:gets).chomp
      print "\n"
      else
        raise ExitException.new("Upgrade to Ruby >= 1.9 for password prompting on the shell. Or you can set password= in your properties file")
      end
    end
  end
end