This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## To run the scraper

```
bundle exec ruby scraper.rb
```

The planning permit register sits behind AWS WAF, which challenges requests that
don't look like they came from a browser and challenges morph.io's US datacentre
address even when they do. The scraper sends a browser User-Agent, and on
morph.io `MORPH_AUSTRALIAN_PROXY` must be set to the url of an Australian proxy
(`http://morph:password@au.proxy.oaf.org.au:8888`). Without it the run fails with
`Blocked by AWS WAF`.

### Expected output

```
Using Australian proxy...
Fetching page 1: https://www.melbourne.vic.gov.au/planning-permit-register-search-results?std=20/08/2026&end=03/09/2026&page=1
  found 10 applications on page 1
Fetching page 2: https://www.melbourne.vic.gov.au/planning-permit-register-search-results?std=20/08/2026&end=03/09/2026&page=2
  found 2 applications on page 2
Fetching page 3: https://www.melbourne.vic.gov.au/planning-permit-register-search-results?std=20/08/2026&end=03/09/2026&page=3
  found 0 applications on page 3
Finished - added 12 records
```

Execution time ~ 10 seconds.

## To run style and coding checks

```
bundle exec rubocop
```
