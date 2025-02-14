# tofu-weather

FiveM weather script for synchronized complex weather systems across all clients, this allows owners & developers to define weather patterns that build on top of the default hashes that most use to enhance the overall weather experience.

### Features
- Primary and Secondary weather modifiers
- Dynamic selection of primary and secondary weather modifiers to ensure complex weather every time.
- Dynamic rain modifier (for weather sets that include rain)
- Dynamic wind speed and wind direction
- Custom moon cycles
- Weather forecast that can be integrated in to phone apps, news papers, etc.
- Locale support

### Dependencies
- [ox_lib](https://github.com/overextended/ox_lib)

### Commands
- `freezeweather` - toggle which will freeze the current weather for all clients
- `generateweather` - generate a new weather forecast for the next 24 hours in game.
- `weatherset` - update all clients to use specific weather set.
