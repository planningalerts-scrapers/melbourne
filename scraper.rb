require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

comment_url = "mailto:planning@melbourne.vic.gov.au"
base_url = "http://www.melbourne.vic.gov.au/building-and-development/property-information/planning-building-registers/Pages/town-planning-permits-register-search-results.aspx"

# Get applications from the last two weeks
start_date = (Date.today - 14).strftime("%d/%m/%Y")
end_date = Date.today.strftime("%d/%m/%Y")

page_number = 1
total_records_saved = 0

begin
  url = "#{base_url}?std=#{start_date}&end=#{end_date}&page=#{page_number}"
  puts "Fetching page #{page_number}: #{url}"
  page = agent.get(url)

  if page.body.size < 1024
    puts "Page was only #{page.body.size} bytes - too small to have useful content!"
  end

  # Find all table rows in the results table (skip header row)
  rows = page.search('div.planning-permit-register-results table tbody tr.table__row')

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
    info_url = relative_url.start_with?('http') ? relative_url : "http://www.melbourne.vic.gov.au#{relative_url}"

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

puts "Scraping complete. Total records saved: #{total_records_saved}"
puts "No applications found in date range!" if total_records_saved == 0
