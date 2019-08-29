# -*- coding: utf-8 -*-
#
# Copyright 2013-2019 Illumio, Inc. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'json'
require 'zlib'
require 'uri'
require 'net/http'
require 'base64'
require 'stringio'
require 'openssl'

def lambda_handler(event)

  hostaddr = ENV['PCE_HOSTADDR']
  org = ENV['PCE_ORG'] ||= '1'
  api_user = ENV['PCE_APIUSER']
  api_token = ENV['PCE_APITOKEN']

  flowdata = []
  
  begin
    log_data = Base64.decode64(event[:event]['awslogs']['data'])
    gz = Zlib::GzipReader.new(StringIO.new(log_data))
    data = JSON.parse(gz.read)

    data['logEvents'].each do |evt|
      next unless evt['message']
      fdata = evt['message'].split(' ')
      next unless fdata[12] == 'ACCEPT'
      flowdata << "#{fdata[3]},#{fdata[4]},#{fdata[6]},#{fdata[7]}"
      puts #{flowdata
    end
    puts "flowdata: #{flowdata}"
    if hostaddr && flowdata.size > 0
      uri = URI("https://#{hostaddr}/api/v1/orgs/#{org}/agents/bulk_traffic_flows")
      puts "uri: #{uri.inspect}"

      req = Net::HTTP::Post.new(uri)
      req.basic_auth(api_user, api_token)
      req.body = flowdata.join("\n")
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        res = http.request(req)
        puts "Response: #{res.inspect}"
      end
    end
    
  rescue => e
    puts e.inspect
    puts e.backtrace
  end
end
