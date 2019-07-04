## Changelog

### 1.1.2

- Improved tests for Sequel versions 4 and 5
- Improved compatibility with several Ruby versions
- Prevent Sequel's warnings about deprecations

### 1.1.1

- Minimum version for Ruby (MRI) >= 2.2
- Improve code quality (Rubocop)
- Update dependencies

### 1.0.0

- Minimum version for Ruby (MRI) >= 2.0
- Minimum version for JRuby (Java) >= 9.0
- Fix some exception messages
- Improve specs over the `pg_array` extension (issue #9)

### 0.3.2

- Hotfixes & minor updates
- Olle Jonsson's contributions

### 0.3.1

- Add support for YAML & JSON files
 - Minor hotfixes

### 0.2.1

- API changes to protect Sequel's namespace
- `Sequel::Seed.environment = :env` is also `Sequel::Seed.setup(:env)`
- `Sequel::Seed` class is now `Sequel::Seed::Base`; `Sequel::Seed` is now a module;
    thus, there's no way to proxy the old `Sequel::Seed.apply` to the new `Sequel::Seed::Base.apply`
- `Sequel::Seeder` and `Sequel::TimestampSeeder` are still the same (no changes in interface as well)
- Improve test coverage to guarantee backward compatibility
- Minor hotfixes

### 0.1.4

- Environment references could be a Symbol or String
- Improve test coverage
- New project website with documentation

### 0.1.2

- Initial version
- Seed descriptor only available as Ruby code
