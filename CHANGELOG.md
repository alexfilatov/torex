# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-05

### Changed
- Updated to support Elixir 1.14+
- Replaced Poison with Jason for JSON encoding
- Updated HTTPoison from 0.13 to 2.0
- Modernized OTP application structure with dedicated `Torex.Application` module
- Changed config format from nested `:tor_server` to flat `tor_host` and `tor_port` keys
- Improved error handling with structured error tuples `{:error, {:http_error, status, body}}`

### Added
- Mox-based test suite with comprehensive coverage
- `Torex.HTTPClient` behaviour for testability
- Content-Type header for POST requests
- LICENSE file
- CHANGELOG file

### Removed
- Poison dependency (replaced by Jason)
- remix dependency (dev-only hot reloading)
- Support for Elixir < 1.14

### Fixed
- Hackney pool initialization (was causing `:req_not_found` errors)
- Runtime vs compile-time configuration lookup

## [0.1.0] - 2017-09-01

### Added
- Initial release
- Basic GET and POST requests through Tor SOCKS5 proxy
- Hackney connection pooling
