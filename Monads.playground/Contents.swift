struct Writer<Value> {
  let value: Value
  let events: [String]

  init(value: Value, events: [String]) {
    self.value = value
    self.events = events
  }

  init(value: Value, event: String) {
    self.value = value
    self.events = ["\(event): \(value)"]
  }

  func flatMap<T>(_ transform: (Value) -> Writer<T>) -> Writer<T> {
    let transformed = transform(value)

    var newEvents = events

    newEvents.append(contentsOf: transformed.events)

    return Writer<T>(value: transformed.value, events: newEvents)
  }
}

func addTwo(value: Int) -> Writer<Int> {
  return Writer(value: value + 2, event: "Added two")
}

func multiplyTwo(value: Int) -> Writer<Int> {
  return Writer(value: value * 2, event: "Mulitplied by two")
}

func divideFive(value: Int) -> Writer<Double> {
  return Writer(value: Double(value) / 5 , event: "Divided by three")
}

let writer = Writer(value: 5, event: "Initial value")
  .flatMap(addTwo)
  .flatMap(multiplyTwo)
  .flatMap { Writer(value: $0 - 5, event: "Subtracted five") }
  .flatMap(divideFive)

print("Value: \(writer.value)")
print("Events: \(writer.events)")


struct IO<Value> {
  let action: () -> Value

  func map<T>(_ transform: @escaping (Value) -> T) -> IO<T> {
    return IO<T> { transform(self.action()) }
  }

  func flatMap<T>(_ transform: @escaping (Value) -> IO<T>) -> IO<T> {
    return IO<T> { transform(self.action()).action() }
  }

  func then<T>(_ ioT: IO<T>) -> IO<T> {
    return flatMap { _ in ioT }
  }
}

let ioReadline: IO<String> = IO { readLine() ?? "Hello world!" }

let ioPrint: (String) -> IO<Void> = { msg in IO { print(msg) }}

let echo: IO<Void> = ioPrint("Please enter some text:")
  .then(ioReadline)
  .map { $0.uppercased() }
  .flatMap(ioPrint)

echo.action()
