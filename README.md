# ktlint_reporter

This is a plugin of [Danger](https://github.com/danger/danger) for Android projects.
This reports checkstyle results.

## Installation

`gem install ktlint_reporter`

## Usage

`checkstyle_reports` namespace is available under Dangerfile.
    
### Report errors

```
# If you'd like inlining comments
checkstyle_reports.inline_comment = true
# If you want to filter only modified lines
checkstyle_reports.filtering_lines = true
checkstyle_reports.report(/path/to/xml)
```

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
