#!/bin/bash
# chmod +x bash/publish.sh && ./bash/publish.sh

dart format .
cd packages
cd ispectify
dart pub publish --skip-validation
cd ..
cd ispectify_bloc
dart pub publish --skip-validation
cd ..
cd ispectify_dio
dart pub publish --skip-validation
cd ..
cd ispectify_http
dart pub publish --skip-validation
cd ..
cd ispectify_ws
dart pub publish --skip-validation
cd ..
cd ispect
dart pub publish --skip-validation
cd ..
cd ispect_jira
dart pub publish --skip-validation
cd ..
cd ..
