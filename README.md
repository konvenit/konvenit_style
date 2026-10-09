# KonvenitStyle [![CI](https://github.com/konvenit/konvenit_style/actions/workflows/ci.yml/badge.svg)](https://github.com/konvenit/konvenit_style/actions/workflows/ci.yml)

This gem checks the style for Rails projects.

## create a new version

1. bump the version number lib/konvenit_style/version.rb
```
  VERSION = "1.16.4"
```

2. commit the changes and push to master
```
git commit -am "v1.16.4" # Version number is 1.16.4
git push
```

3. Tag the new release

```
git tag -a v1.16.4 -m "Changes TODO"
git push origin v1.16.4
```

## Installation

Add this line to your Gemfile:

```ruby
gem "konvenit_style", git: "git@github.com:konvenit/konvenit_style.git", require: false
```

## Usage


add the following to the top of your `.rubocop.yml` file:

```yaml
inherit_gem:
  konvenit_style: rails/rubocop.yml
```

## Custom cops

### Konvenit/CommentLength

Limits full-line comment blocks to 2 lines. Magic comments, rubocop directives and
`annotate` blocks are ignored.

The cop is disabled for normal rubocop runs, so existing code is not affected. It only
checks lines changed in a pull request. Add this workflow to your project:

```yaml
# .github/workflows/comment_length.yml
name: Comment length

on: pull_request

jobs:
  comment_length:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - uses: reviewdog/action-rubocop@v2
        with:
          skip_install: true
          use_bundler: true
          rubocop_flags: --only Konvenit/CommentLength
          reporter: github-pr-review
          filter_mode: added
          fail_level: error
```

To check your current changes locally:

```
bundle exec rubocop --only Konvenit/CommentLength $(git diff --name-only master -- '*.rb')
```
