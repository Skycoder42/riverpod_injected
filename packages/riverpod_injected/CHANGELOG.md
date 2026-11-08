# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## \[Unreleased\]
### Deprecated
- `ScopedRef.exists` - use `ref.read(provider.exists)` instead

## [1.3.1] - 2026-11-08
### Changed
- Updated dependencies

## [1.3.0] - 2026-09-18
### Changed
- Fix command runner API

## [1.2.2] - 2026-09-16
### Fixed
- Fix nested subcommands not being correctly initialized

## [1.2.1] - 2026-09-10
### Changed
- Rename `ScopedRef` methods. `watch` is now `stream` and `keep` is now `watch`

## [1.2.0+1] - 2026-09-10
### Fixed
- Added missing export

## [1.2.0] - 2026-09-08
### Added
- Added `riverpodScope` method to create managed scopes for CLI based applications.
- Added `RiverpodCommandRunner` helper class to run commands within a managed Riverpod scope.

## [1.1.0] - 2026-09-03
### Changed
- `@Riverpod` is now generated via explicit parameters instead of nesting the annotation.

## [1.0.0] - 2026-08-27
### Changed
- Initial Release

[1.3.1]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.3.0...riverpod_injected-v1.3.1
[1.3.0]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.2.2...riverpod_injected-v1.3.0
[1.2.2]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.2.1...riverpod_injected-v1.2.2
[1.2.1]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.2.0+1...riverpod_injected-v1.2.1
[1.2.0+1]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.2.0...riverpod_injected-v1.2.0+1
[1.2.0]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.1.0...riverpod_injected-v1.2.0
[1.1.0]: https://github.com/Skycoder42/riverpod_injected/compare/riverpod_injected-v1.0.0...riverpod_injected-v1.1.0
[1.0.0]: https://github.com/Skycoder42/riverpod_injected/releases/tag/riverpod_injected-v1.0.0
