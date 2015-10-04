Sequel.seed(:development, :test) do # Applies only to "development" and "test" environments
  def run
    User.create \
      full_name: "Richard Feynman",
      profession: "Theoretical physicist",
      username: "rfeynman",
      password: "271828"
  end
end

Sequel.seed do # Wildcard Seed; applies to every environment
  def run
    [
      ['USD', 'United States dollar'],
      ['BRL', 'Brazilian real']
    ].each do |abbr, name|
      Currency.create abbr: abbr, name: name
    end
  end
end
