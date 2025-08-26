# TODO

## Core
- [ ] Add test coverage
- [ ] Handle runtime config changes and initial values with persistence (web: localStorage; mobile/desktop: SharedPreferences)
- [ ] Redact secrets and sensitive values (headers/body)
- [ ] Performance improvements (virtualized lists, throttling, buffer limits)

## Packages
### ispect
- [ ] Persist panel state, filters, theme
### ispectify
- [ ] OpenTelemetry/OTLP exporter
### ispectify_dio / ispectify_http
- [ ] Redact headers/body; detect binary payloads

---

## Done
- [x] Add CI/CD