# TODO

## Core
- [ ] Handle runtime config changes and initial values with persistence (web: localStorage; mobile/desktop: SharedPreferences)
- [ ] Performance improvements (virtualized lists, throttling, buffer limits)

## Packages
### ispect
- [ ] Persist panel state, filters, theme
### ispectify
- [ ] OpenTelemetry/OTLP exporter

---

## Done
- [x] Add CI/CD
- [x] Redact secrets and sensitive values (headers/body)
- [x] Redact headers/body; detect binary payloads
- [x] Copy cURL command for API requests