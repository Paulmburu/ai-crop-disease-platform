/// Injectable time source so tests and mocks control "now".
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();

/// A clock frozen at [value] (tests, mock screenshots).
Clock fixedClock(DateTime value) =>
    () => value;
