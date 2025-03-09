## 4.0.0
- The same version as the `ispect` package.
- Logs `good`, `provider`, `analytics`, and `print` moved to the `ispectify`.
- Added support to `js_interop` and `web` package.
- Refactor:
   - Added documentation to the ISpectify class.
   - Modified the constructor to accept optional components (logger, observer, options, filter, errorHandler, history).
   - Introduced a configure method to update the configuration of an existing inspector instance.
   - Updated the internal logic to use the new components and options.

## 0.0.4
- Fix:
   - Fixed `_output = output ?? log_output.outputLog;`.

## 0.0.1
- Initial version.