#!/usr/bin/env ruby
# Encoding: utf-8
#
# Author:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2011, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This example gets a label by its ID. To determine which labels exist,
# run get_all_labels.rb.
#
# This feature is only available to DFP premium solution networks.
#
# Tags: LabelService.getLabel

require 'dfp_api'

API_VERSION = :v201206

def get_label()
  # Get DfpApi instance and load configuration from ~/dfp_api.yml.
  dfp = DfpApi::Api.new

  # To enable logging of SOAP requests, set the log_level value to 'DEBUG' in
  # the configuration file or provide your own logger:
  # dfp.logger = Logger.new('dfp_xml.log')

  # Get the LabelService.
  label_service = dfp.service(:LabelService, API_VERSION)

  # Set the ID of the label to get.
  label_id = 'INSERT_LABEL_ID_HERE'.to_i

  # Get the label.
  label = label_service.get_label(label_id)

  if label
    puts "Label with ID: %d, name: '%s' and types '%s' was found." %
        [label[:id], label[:name], label[:types].join(', ')]
  else
    puts 'No label found for this ID.'
  end
end

if __FILE__ == $0
  begin
    get_label()

  # HTTP errors.
  rescue AdsCommon::Errors::HttpError => e
    puts "HTTP Error: %s" % e

  # API errors.
  rescue DfpApi::Errors::ApiException => e
    puts "Message: %s" % e.message
    puts 'Errors:'
    e.errors.each_with_index do |error, index|
      puts "\tError [%d]:" % (index + 1)
      error.each do |field, value|
        puts "\t\t%s: %s" % [field, value]
      end
    end
  end
end
