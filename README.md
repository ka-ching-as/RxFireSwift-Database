# RxFireSwift-Database
RxSwift extensions for the Firebase Realtime Database

## Usage

Please refer to the [FireSwift-Database project](https://github.com/ka-ching-as/FireSwift-Database) for a description of the `Codable` firebase extensions and the `Path` concept.

In the following example, assume that we have a type `Configuration` that conforms to `Codable`.

Instead of 
```
let handle = ref.observe(.value) { snapshot in
     // Check if snapshot exists
     guard snapshot.exists() else { // Handle error }
     guard let value = snapshot.value else { // Handle error }
     
     // Custom parsing of snapshot value
     do { 
        let value = try customParsing(value)
     } catch {
         // Handle error
     }
}
```
you can get `Observable`s of `Decodable` types directly from the Firebase API:

```
let configurationPath = Path().configuration
let s = FirebaseService(database)
let configObservable = s.observe(at: configurationPath)
```

The variable `configObservable` is of type `Observable<DecodeResult<Configuration>>` and you can subscribe to this as you would any other observable.

Since you may not always wish to handle errors, the framework provides convenience methods for filtering only the success part of the results:

```
let configObservable = s.observe(at: configurationPath).successes()
```
Here `configObservable` is of type `Observable<Configuration>`

If you expect that data may not be present at the path, you can get an `Observable` of `Optionals` as follows:
```
let configObservable = s.observe(at: configurationPath).ifPresent()
```
Here `configObservable` is of type `Observable<Configuration?>`

There are also variations of the `successes` and `ifPresent` filters that allow you to pass in an error handler for the events that are otherwise filtered away. This can be a convenient way to add logging.

The `FirebaseService` abstraction allows you to basically factor out any knowledge about the firebase realtime database, since it only exposes `Observable` types that may as well come from any other source. This could allow us to swap out the implementation with another technology like for instance FireStore in the future.

Furthermore the `FirebaseService` abstraction allows you to provide configuration of the `StructureEncoder` and `StructureDecoder` used internally. These take similar configuration to those of `JSONEncoder` and `JSONDecoder` of the Swift Standard Library. Like `dateEncodingStrategy`, `keyEncodingStrategy`, etc.

## Installation

### Using [Carthage](https://github.com/Carthage/Carthage)

**Tested with `carthage version`: `0.31.0`**

Add this to `Cartfile`

```
github "ka-ching/RxFireSwift-Database" ~> 0.1
```

```bash
$ carthage update
```

### Automatic code generation

Please refer to the README.md of [`FireSwift-Database`](https://github.com/ka-ching-as/FireSwift-Database) for a description of the automatic generation of typesafe `Path`s.

## TODO

- [ ] Is .successes() a good name for the `success` filter of the observed results?

## License

[Apache licensed.](LICENSE)

## About

RxFireSwift-Database is maintained by Ka-ching.
