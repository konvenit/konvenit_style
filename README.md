# KonvenitStyle

This gem checks the style for Rails projects.

## create a new version

1. bump the version number lib/konvenit_style/version.rb
```
  VERSION = "1.16.3"
```

2. commit the changes and push to master
```
git commit -am "v1.16.3" # Version number is 1.16.3
git push
```

3. Tag the new release

```
git tag -a v1.16.3 -m "Changes TODO"
git push origin v1.16.3
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
