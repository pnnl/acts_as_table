# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.4] - 2021-06-21
### Fixed
- Infinite loop when traversing persisted row model, #8.

## [0.0.3] - 2021-06-15
### Fixed
- Typo in YARD tag, #3.
- Method not found, #4.
- Associate record errors with record and value, #5.
- Move foreign key declarations in migration, #6.
### Enhancement
- Added `ActsAsTable::HeadersNotFound` and `ActsAsTable::InvalidHeaders` (subclasses of `ArgumentError`).

## [0.0.2] - 2021-06-10
### Fixed
- Inverse of association not found, #1.

## [0.0.1] - 2021-01-06
- Initial commit.

[0.0.4]: https://github.com/pnnl/acts_as_table/releases/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/pnnl/acts_as_table/releases/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/pnnl/acts_as_table/releases/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/pnnl/acts_as_table/releases/tag/v0.0.1
