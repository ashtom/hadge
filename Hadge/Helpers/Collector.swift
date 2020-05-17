infix operator >=>: AdditionPrecedence

public typealias Collector = (@escaping () -> Void) -> Void
public func || (first: @escaping Collector, second: @escaping Collector) -> Collector {
    return { combine in
        first {
            second {
                combine()
            }
        }
    }
}
