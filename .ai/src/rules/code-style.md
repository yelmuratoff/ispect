# Code Style Rules

## Dart Style

- Keep analyzer strictness clean: `strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, and `always_declare_return_types` are enabled.
- Prefer explicit return types on functions and getters.
- Prefer `final` locals and immutable constructor parameters unless mutation is part of the API.
- Use `const` constructors and literals where the existing widget/model code supports them.
- Use records for small internal tuples when the surrounding code already does, such as redacted URL/path returns.

## Naming

- Keep package prefixes consistent: public ISpect APIs use `ISpect*`; adapter settings use `ISpectDioInterceptorSettings`, `ISpectHttpInterceptorSettings`, and similar names.
- Use log keys and trace category IDs as stable kebab-case strings (`http-request`, `db-error`).
- Use metadata keys already centralized in `NetworkJsonKeys`, `TraceKeys`, and DB constants instead of repeating string literals.

## Formatting

- Run `dart format` on changed Dart files.
- Keep generated localization files and generated README outputs out of manual style refactors.
- Keep documentation comments focused on public API behavior, compile-time gating, redaction, or migration decisions.

## Anti-Patterns

- Do not use `print` or `debugPrint` for package logging except for existing gated warnings in initialization paths.
- Do not replace established small helpers with generated code.
- Do not add untyped `Map` or `List` values where the analyzer can infer a precise type.
