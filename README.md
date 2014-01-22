# Rocky Balboa

## Requirements

- Ruby 2.0
- Portaudio >= 19
- Mpg123 >= 1.14


### OSX Install
```console
brew install portaudio
brew install mpg123

bundle install
cp .env.example .env
```

## Get in action!

```console
FROM=2014-01-23 TO=2014-01-26 ruby rocky_balboa.rb
```

