# TODO

### Extension Methods
- [ ] Add color calculation extensions for JSON viewer

### Code Style
- [ ] Fix commented-out duplicate declarations in `daily_file_history.dart:304`

### Error Handling
- [ ] Fix silent error swallowing in `logs_json_service.dart:122-130` (add logging)
- [ ] Add validation before type casts throughout codebase
- [ ] Improve error messages to be more actionable
- [ ] Add error recovery mechanisms

---

## Priority 4 - Low (Modern Patterns & Testing)

### Testing
- [ ] Increase test coverage from current ~11% to >80%
- [ ] Add unit tests for:
  - [ ] File I/O operations
  - [ ] JSON serialization
  - [ ] Filtering logic
  - [ ] Redaction service
  - [ ] Session management
- [ ] Create test utilities/fixtures for common scenarios
- [ ] Set up code coverage reporting in CI/CD

### Modern Dart/Flutter Patterns
- [ ] Use Dart 3.0 sealed classes for state representations
- [ ] Apply pattern matching consistently across codebase
- [ ] Use records for multiple return values (already started, make consistent)
- [ ] Leverage const constructors more aggressively

---

## Metrics to Track

### Performance Metrics
- [ ] Set up widget rebuild tracking (DevTools)
- [ ] Measure JSON encoding time before/after isolate migration
- [ ] Track file I/O latency
- [ ] Monitor memory usage over time
- [ ] Track FPS during heavy logging

### Code Quality Metrics
- [ ] Test coverage % (target: >80%)
- [ ] Average method length (target: <50 lines)
- [ ] Cyclomatic complexity (target: <10 per method)
- [ ] Code duplication % (target: <5%)
- [ ] Number of SOLID violations

### Security Metrics
- [ ] Redaction coverage in tests
- [ ] Encryption validation test coverage
- [ ] Input validation coverage

---

## Done
- [x] Expand redaction patterns to include: SSN, credit cards, bank accounts, phone numbers, passport, driver license
- [x] Add input validation for JSON import (size limits, depth limits, schema validation)
- [x] Add DoS protection for deeply nested JSON (included in JSON validation)
- [x] Add CI/CD
- [x] Add extension methods for date formatting
- [x] Create error handling utility to eliminate duplication
- [x] Use Sets instead of Lists for type filtering
- [x] Add try-finally blocks around resource cleanup
- [x] Document performance characteristics in method docs
- [x] Add size/depth validation to JSON import
- [x] Fix RepaintBoundary placement in JSON viewer
- [x] Redact secrets and sensitive values (headers/body)
- [x] Redact headers/body; detect binary payloads
- [x] Copy cURL command for API requests
- [x] Performance improvements (virtualized lists, throttling, buffer limits)
- [x] Handle runtime config changes and initial values with persistence (web: localStorage; mobile/desktop: SharedPreferences)
- [x] Add `DateTimeFormatting` extension for date operations
- [x] Add `toFileNameFormat()` method
- [x] Add `isSameDay()` method
- [x] Add error handling extension for conditional logging
- [x] Replace abbreviated variable names (`e`, `st`) with descriptive names (`exception`, `stackTrace`) (partially done)
- [x] Add clear variable names in date comparison logic
- [x] Extract duplicate date validation logic to utility class (DateTimeFormatting extension)
- [x] Extract repeated error handling pattern (appears 15+ times) to extension method
- [x] Fix image disposal in `inspector.dart:275-291` (add try-finally)
- [x] Audit all Timer cancellations in `custom_expansion_tile.dart` (verified - properly cancelled)
- [x] Add dispose guards for all resources
- [x] Replace quadratic date comparison with Set-based lookup in `daily_file_history.dart:284-287`
- [x] Fix widget rebuild boundaries in `json_attribute.dart:165-167` (RepaintBoundary should wrap AnimatedBuilder)
- [x] Use Set instead of List for type filtering (O(1) vs O(n) lookups)
- [x] Refactor `json_attribute.dart` (806 lines) - separate caching, rendering, search
- [x] Refactor `ispectify.dart` (565 lines) - extract observer management
- [x] Replace O(n) filter searches with indexed map in `ispect_view_controller.dart:188-196`
- [x] Optimize expensive color calculations in JSON viewer
- [x] Optimize nested ValueListenableBuilders in `inspector.dart:406-470`
- [x] **DIP**: Create abstract `PlatformDirectory` interface for platform-specific code
- [x] Extract platform detection from business logic
- [x] Create proper abstraction layer for file system operations
- [x] **SRP**: Split `ISpectViewController` into:
  - [x] `FilterManager` - Handle filtering logic
  - [x] `SettingsManager` - Handle settings
  - [x] `LogExportService` - Handle exports
  - [x] `LogImportService` - Handle imports
- [x] **OCP**: Implement strategy pattern for `RedactionService`
  - [x] `KeyBasedRedaction` strategy
  - [x] `PatternBasedRedaction` strategy
  - [x] `CompositeRedactionStrategy` for combining strategies
- [x] **DIP**: Add dependency injection to `Inspector` (inject controller)
- [x] Create shared base class for interceptors (dio/http/ws)
- [x] Consolidate chunking logic (appears in 3+ places with different implementations)