# Orthoses

Orthoses is a framework for RBS generation.
The Rack architecture keeps your code organized and extensible.

## PoC

https://gist.github.com/ksss/00592da24f28774bf8fc5db08331666e

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add orthoses

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install orthoses

## Usage

```rb
Orthoses::Builder.new do
  use Orthoses::CreateFileByName
    base_dir: Rails.root.join("sig/out"),
    header: "# !!! GENERATED CODE !!!"
  use Orthoses::Filter,
    if: -> (name, _content) {
      path, _lineno = Object.const_source_location(name)
      return false unless path
      %r{app/models}.match?(path)
    }
  use YourCustom::Middleware
  use Orthoses::IncludeExtendPrepend
  use Orthoses::Constant
  use Orthoses::Walk,
    root: "Foo"
  run -> () {
    # load library or application
  }
end.call
```

## Middlewares

### Orthoses::Constant

Add constant signature to class/module.
Signatures are predicted from constant values.

### Orthoses::IncludeExtendPrepend

Add module include/extend/prepend definition.
It use `Module#{includeed,extended,prepended}` for capture.

### Orthoses::ObjectSpaceAll

Add module/class by `ObjectSpace.each_object(Module)`

### Orthoses::CreateFileByName

Separate directories for each module name and output RBS files.

### Orthoses::Filter

Filter stored value by name and content.

### Orthoses::PP

Debug pring current stored values

### Orthoses::Load

Load RBS from `dir`.
And loaded RBS will write to output.

### Orthoses::Walk

Load class/module recersive from `root` constant.
If set String to `root`, It get constant after loading.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ksss/orthoses. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ksss/orthoses/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Orthoses project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ksss/orthoses/blob/main/CODE_OF_CONDUCT.md).
