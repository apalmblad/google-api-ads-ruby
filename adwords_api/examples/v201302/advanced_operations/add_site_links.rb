#!/usr/bin/env ruby
# Encoding: utf-8
#
# Author:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2013, Google Inc. All Rights Reserved.
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
# This example adds a sitelinks feed and associates it with a campaign.
#
# Tags: CampaignFeedService.mutate, FeedItemService.mutate
# Tags: FeedMappingService.mutate, FeedService.mutate

require 'adwords_api'

def add_site_links(campaign_id)
  # AdwordsApi::Api will read a config file from ENV['HOME']/adwords_api.yml
  # when called without parameters.
  adwords = AdwordsApi::Api.new

  # To enable logging of SOAP requests, set the log_level value to 'DEBUG' in
  # the configuration file or provide your own logger:
  # adwords.logger = Logger.new('adwords_xml.log')

  feed_srv = adwords.service(:FeedService, API_VERSION)
  feed_item_srv = adwords.service(:FeedItemService, API_VERSION)
  feed_mapping_srv = adwords.service(:FeedMappingService, API_VERSION)
  campaign_feed_srv = adwords.service(:CampaignFeedService, API_VERSION)

  sitelinks_data = {}

  # Create site links feed first.
  site_links_feed = {
    :name => 'Feed For Site Links',
    :attributes => [
      {:type => 'STRING', :name => 'Link Text'},
      {:type => 'URL', :name => 'Link URL'}
    ]
  }

  response = feed_srv.mutate([
      {:operator => 'ADD', :operand => site_links_feed}
  ])
  if response and response[:value]
    feed = response[:value].first
    # Attribute of type STRING.
    link_text_feed_attribute_id = feed[:attributes][0][:id]
    # Attribute of type URL.
    link_url_feed_attribute_id = feed[:attributes][1][:id]
    puts "Feed with name '%s' and ID %d was added with" %
        [feed[:name], feed[:id]]
    puts "\tText attribute ID %d and URL attribute ID %d." %
        [link_text_feed_attribute_id, link_url_feed_attribute_id]
    sitelinks_data[:feed_id] = feed[:id]
    sitelinks_data[:link_text_feed_id] = link_text_feed_attribute_id
    sitelinks_data[:link_url_feed_id] = link_url_feed_attribute_id
  else
    raise new StandardError, 'No feeds were added.'
  end

  # Create site links feed items.
  items_data = [
    {:text => 'Home', :url => 'http://www.example.com'},
    {:text => 'Stores', :url => 'http://www.example.com/stores'},
    {:text => 'On Sale', :url => 'http://www.example.com/sale'},
    {:text => 'Support', :url => 'http://www.example.com/support'},
    {:text => 'Products', :url => 'http://www.example.com/products'},
    {:text => 'About', :url => 'http://www.example.com/about'}
  ]

  feed_items = items_data.map do |item|
    {
      :feed_id => sitelinks_data[:feed_id],
      :attribute_values => [
        {
          :feed_attribute_id => sitelinks_data[:link_text_feed_id],
          :string_value => item[:text]
        },
        {
          :feed_attribute_id => sitelinks_data[:link_url_feed_id],
          :string_value => item[:url]
        }
      ]
    }
  end

  feed_items_operations = feed_items.map do |item|
    {:operator => 'ADD', :operand => item}
  end

  response = feed_item_srv.mutate(feed_items_operations)
  if response and response[:value]
    sitelinks_data[:feed_item_ids] = []
    response[:value].each do |feed_item|
      puts 'Feed item with ID %d was added.' % feed_item[:feed_item_id]
      sitelinks_data[:feed_item_ids] << feed_item[:feed_item_id]
    end
  else
    raise new StandardError, 'No feed items were added.'
  end

  # Create site links feed mapping.
  feed_mapping = {
    :placeholder_type => PLACEHOLDER_SITELINKS,
    :feed_id => sitelinks_data[:feed_id],
    :attribute_field_mappings => [
      {
        :feed_attribute_id => sitelinks_data[:link_text_feed_id],
        :field_id => PLACEHOLDER_FIELD_SITELINK_LINK_TEXT
      },
      {
        :feed_attribute_id => sitelinks_data[:link_url_feed_id],
        :field_id => PLACEHOLDER_FIELD_SITELINK_LINK_URL
      }
    ]
  }

  response = feed_mapping_srv.mutate([
      {:operator => 'ADD', :operand => feed_mapping}
  ])
  if response and response[:value]
    feed_mapping = response[:value].first
    puts ('Feed mapping with ID %d and placeholder type %d was saved for feed' +
        ' with ID %d.') % [
          feed_mapping[:feed_mapping_id],
          feed_mapping[:placeholder_type],
          feed_mapping[:feed_id]
        ]
  else
    raise new StandardError, 'No feed mappings were added.'
  end

  # Create site links campaign feed.
  operands = sitelinks_data[:feed_item_ids].map do |feed_item_id|
    {
      :xsi_type => 'ConstantOperand',
      :type => 'LONG',
      :long_value => feed_item_id
    }
  end

  function = {
    :operator => 'IN',
    :lhs_operand => [
      {:xsi_type => 'RequestContextOperand', :context_type => 'FEED_ITEM_ID'}
    ],
    :rhs_operand => operands
  }

  campaign_feed = {
    :feed_id => sitelinks_data[:feed_id],
    :campaign_id => campaign_id,
    :matching_function => function,
    # Specifying placeholder types on the CampaignFeed allows the same feed
    # to be used for different placeholders in different Campaigns.
    :placeholder_types => [PLACEHOLDER_SITELINKS]
  }

  response = campaign_feed_srv.mutate([
      {:operator => 'ADD', :operand => campaign_feed}
  ])
  if response and response[:value]
    campaign_feed = response[:value].first
    puts 'Campaign with ID %d was associated with feed with ID %d.' %
      [campaign_feed[:campaign_id], campaign_feed[:feed_id]]
  else
    raise new StandardError, 'No campaign feeds were added.'
  end
end

if __FILE__ == $0
  API_VERSION = :v201302

  # See the Placeholder reference page for a list of all the placeholder types
  # and fields, see:
  #     https://developers.google.com/adwords/api/docs/appendix/placeholders
  PLACEHOLDER_SITELINKS = 1
  PLACEHOLDER_FIELD_SITELINK_LINK_TEXT = 1
  PLACEHOLDER_FIELD_SITELINK_LINK_URL = 2

  begin
    # Campaign ID to add site link to. Campaign must be enhanced.
    campaign_id = 'INSERT_CAMPAIGN_ID_HERE'.to_i
    add_site_links(campaign_id)

  # HTTP errors.
  rescue AdsCommon::Errors::HttpError => e
    puts "HTTP Error: %s" % e

  # API errors.
  rescue AdwordsApi::Errors::ApiException => e
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
