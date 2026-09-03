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

## Debugging

Set `DEBUG` (or `MORPH_DEBUG` in the morph.io scraper settings) to turn on
debug output. Levels are cumulative:

| Level | Output |
| --- | --- |
| `1` | Proxy host and User-Agent in use, a line per request, the response status and size, and the response headers that matter when the register blocks us (`x-amzn-waf-action`, `x-cache`, `age`, `via`, `x-amz-cf-pop`). Every application saved, and every row skipped as malformed. |
| `2` | All request and response headers, values over 200 characters truncated, and each record as it is saved. |
| `3` | The first 2kB of each page body, and headers in full. |

A value that is not a number, such as `DEBUG=true`, means level 1.

```
DEBUG=1 bundle exec ruby scraper.rb
```

Level 1 is the useful one when the register returns nothing:

```
Fetching page 1: https://www.melbourne.vic.gov.au/planning-permit-register-search-results?std=20/08/2026&end=03/09/2026&page=1
  > GET /planning-permit-register-search-results?std=20/08/2026&end=03/09/2026&page=1
  < 202 0 bytes
  <   content-type: text/html; charset=UTF-8
  <   content-length: 0
  <   x-amzn-waf-action: challenge
  <   x-cache: Error from cloudfront
  <   via: 1.1 f3a04c27f130696f2f529b1a181d2d46.cloudfront.net (CloudFront)
  <   x-amz-cf-pop: PER50-P3
```

Requests are logged from Mechanize hooks, so redirects and the error responses
that make `agent.get` raise are logged too. The proxy password is never
printed.

## To run style and coding checks

```
bundle exec rubocop
```
