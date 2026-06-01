import CoreGraphics

extension Collection where Element == CGFloat {

    func extremums() -> (min: CGFloat, max: CGFloat) {
        return self
            .reduce((min: CGFloat(0), max: CGFloat(0))) { extremums, current in
                (Swift.min(extremums.min, current), Swift.max(extremums.max, current))
            }
    }
}
