public enum LoadableState<Value>: Sendable where Value: Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(AppError)
}
