require 'rack/rewrite'

CANONICAL_SERVER_NAME = "gregbee.ch"
use Rack::Rewrite do
  r301 /.*/, "http://#{CANONICAL_SERVER_NAME}$&", :if => Proc.new { |rack_env| 
    ENV["RACK_ENV"] == "production" && rack_env["SERVER_NAME"] != CANONICAL_SERVER_NAME
  }
end

require './site'

run MySite.new