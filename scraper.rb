#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
Bundler.require

require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

if ENV["MORPH_AUSTRALIAN_PROXY"]
  # On morph.io set the environment variable MORPH_AUSTRALIAN_PROXY to
  # http://morph:password@au.proxy.oaf.org.au:8888 replacing password with
  # the real password.
  puts "Using Australian proxy..."
  agent.agent.set_proxy(ENV["MORPH_AUSTRALIAN_PROXY"])
end

# The register sits behind AWS WAF, which challenges requests that don't look
# like they came from a browser (planningalerts-scrapers/issues#977). A browser
# User-Agent is enough from an Australian connection, but morph.io runs from a
# US datacentre and is challenged even with one, so it needs the proxy above as
# well.
agent.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                   "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"

comment_url = "mailto:planning@melbourne.vic.gov.au"
site_url = "https://www.melbourne.vic.gov.au"
base_url = "#{site_url}/planning-permit-register-search-results"

# Get applications from the last two weeks
start_date = (Date.today - 14).strftime("%d/%m/%Y")
end_date = Date.today.strftime("%d/%m/%Y")

page_number = 1
total_records_saved = 0

begin
  url = "#{base_url}?std=#{start_date}&end=#{end_date}&page=#{page_number}"
  puts "Fetching page #{page_number}: #{url}"
  page = agent.get(url)

  # A challenged request comes back as an empty 202 - AWS WAF only renders the
  # challenge page itself for requests that accept text/html - so fail loudly
  # rather than quietly reporting no applications.
  waf_action = page.response['x-amzn-waf-action']
  if waf_action
    raise "Blocked by AWS WAF (x-amzn-waf-action: #{waf_action}). " \
          "Set MORPH_AUSTRALIAN_PROXY to the url of an Australian proxy."
  end

  results = page.at('div.planning-permit-register-results')
  raise "No results section on #{url} - has the page layout changed?" unless results

  # Find all table rows in the results table (skip header row)
  rows = results.search('table tbody tr.table__row')

  puts "  found #{rows.size} applications on page #{page_number}"

  rows.each do |row|
    cells = row.search('td.table__cell')
    next if cells.size < 5  # Skip malformed rows

    # Extract data from table cells
    application_cell = cells[0]
    received_cell = cells[1]
    address_cell = cells[2]
    proposal_cell = cells[3]
    status_cell = cells[4]

    # Get the application number and construct info URL
    application_link = application_cell.at('a')
    next unless application_link

    council_reference = application_link.inner_text.strip
    relative_url = application_link['href']
    info_url = relative_url.start_with?('http') ? relative_url : "#{site_url}#{relative_url}"

    # Parse the received date
    received_text = received_cell.inner_text.strip
    day, month, year = received_text.split('/')
    date_received = Date.new(year.to_i, month.to_i, day.to_i).to_s

    # Extract address (remove any trailing whitespace)
    address = address_cell.inner_text.strip

    # Extract proposal description
    description = proposal_cell.inner_text.strip

    # Extract status
    status = status_cell.inner_text.strip

    # Create the record
    record = {
      "council_reference" => council_reference,
      "date_received" => date_received,
      "address" => address,
      "description" => description,
      "status" => status,
      "info_url" => info_url,
      "comment_url" => comment_url,
      "date_scraped" => Date.today.to_s
    }

    ScraperWiki.save_sqlite(['council_reference'], record)
    total_records_saved += 1
  end

  page_number += 1
  # Safety check to prevent infinite loops
  raise "15 pages processed: aborting due to probably infinite loop" if page_number > 15

end until rows.empty?

puts "No applications found in date range!" if total_records_saved.zero?
puts "Finished - added #{total_records_saved} records"
