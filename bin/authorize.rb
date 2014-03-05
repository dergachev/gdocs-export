#!/usr/bin/env ruby

OAUTH_SERVER_PORT = 12736

require 'rubygems'
require 'webrick'
require 'signet/oauth_2/client'
require 'yaml'

ARGV.unshift('--help') if ARGV.empty?

module Google
 class InstalledAppFlow
    def initialize(options)
      @port = options[:port] || 9292
      @authorization = Signet::OAuth2::Client.new({
        :authorization_uri => 'https://accounts.google.com/o/oauth2/auth',
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :redirect_uri => "http://localhost:#{@port}/"}.update(options)
      )
    end

    def authorize
      auth = @authorization

      server = WEBrick::HTTPServer.new(
        :Port => @port,
        :BindAddress =>"0.0.0.0",
        :Logger => WEBrick::Log.new(STDERR, 0),
        :AccessLog => []
      )
      trap("INT") { server.shutdown }

      server.mount_proc '/' do |req, res|
        auth.code = req.query['code']
        if auth.code
          auth.fetch_access_token!
        end
        res.status = WEBrick::HTTPStatus::RC_ACCEPTED
        res.body = <<-HTML
          <html>
            <head>
              <script>
                function closeWindow() {
                  window.open('', '_self', '');
                  window.close();
                }
                setTimeout(closeWindow, 10);
              </script>
            </head>
            <body>You may close this window.</body>
          </html>
        HTML

        server.stop
      end

      STDERR.puts "Visit the following URL to authorize:\n  #{auth.authorization_uri.to_s}"
      server.start
      if @authorization.access_token
        return @authorization
      else
        return nil
      end
    end
  end

  class CLI
    def self.oauth_2_login(options)
      flow = Google::InstalledAppFlow.new(
        :port => OAUTH_SERVER_PORT,
        :client_id => options[:client_credential_key],
        :client_secret => options[:client_credential_secret],
        :scope => options[:scope]
      )

      oauth_client = flow.authorize
      if oauth_client
        config = {
          "mechanism" => "oauth_2",
          "scope" => options[:scope],
          "client_id" => oauth_client.client_id,
          "client_secret" => oauth_client.client_secret,
          "access_token" => oauth_client.access_token,
          "refresh_token" => oauth_client.refresh_token
        }
        # AUTHFILE_YAML_PATH = 'google-api-authorization.yaml'
        # config_file = File.expand_path(AUTHFILE_YAML_PATH)
        # open(config_file, 'w') { |file| file.write(YAML.dump(config)) }
        STDERR.puts "Success! Received the following credentials (also printing them to STDOUT):"
        STDERR.puts YAML.dump(config)
        STDOUT.puts YAML.dump(config)

      end
      exit(0)
    end
  end
end

Google::CLI::oauth_2_login({ :client_credential_key => ARGV[0], :client_credential_secret => ARGV[1], :scope => ARGV[2] })
