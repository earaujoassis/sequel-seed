# Sequel::Seed [![Gem Version](https://badge.fury.io/rb/sequel-seed.svg)](http://badge.fury.io/rb/sequel-seed) ![Travis-CI status](https://travis-ci.org/earaujoassis/evolve.svg?branch=master "Travis-CI status")

> A Sequel extension to make seeds/fixtures manageable like migrations

## Usage

Create a seed file (eg. `/path/to/seeds/20150928071637_currencies.rb`)

```rb
Sequel.seed(:development, :test) do # Applies only to "development" and "test" environments
  def run
    [
      ['USD', 'United States dollar'],
      ['BRL', 'Brazilian real']
    ].each do |abbr, name|
      Currency.create abbr: abbr, name: name
    end
  end
end
```

Set the environment

```rb
Sequel::Seed.environment = :development
```

Load the extension

```rb
require 'sequel'
require 'sequel/extensions/seed'

Sequel.extension :seed
```

Apply the seeds/fixtures

```rb
DB = Sequel.connect(...)
Sequel::Seeder.apply(DB, "/path/to/seeds")
```

For more information, please check the [project website](//github.com/earaujoassis/sequel-seed/).

## Limitations

Only timestamped seeds files

## What's next?

JSON &amp; YAML files as fixtures/seeds

## Support

If you need any help (or have found any bug &#x1f41e;), please post it on
[/issues](//github.com/earaujoassis/sequel-seed/issues). Thank you!

## License

[MIT License](http://earaujoassis.mit-license.org/) &copy; Ewerton Assis
