# Sequel::Seed

> A Sequel extension to make seeds/fixtures manageable like migrations

## Usage

Load the extension

```rb
require 'sequel'
require 'sequel/extensions/seed'

Sequel.extension :seed
```

Create a seed file (eg. `/path/to/seeds/20150928071637_currencies`)

```rb
Sequel.seed(:development, :test, :production) do
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

Apply the seeds/fixtures

```rb
DB = Sequel.connect(...)
Sequel::Seeder.apply(DB, "/path/to/seeds")
```

## Limitations

Only timestamped seeds files

## License

[MIT License](http://earaujoassis.mit-license.org/) &copy; Ewerton Assis
