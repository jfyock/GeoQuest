import CoreLocation

enum GeoHash {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    static func encode(latitude: Double, longitude: Double, precision: Int = AppConstants.geoHashPrecision) -> String {
        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)
        var isEvenBit = true
        var bit = 0
        var charIndex = 0
        var hash = ""

        while hash.count < precision {
            if isEvenBit {
                let mid = (lonRange.0 + lonRange.1) / 2
                if longitude >= mid {
                    charIndex = charIndex | (1 << (4 - bit))
                    lonRange.0 = mid
                } else {
                    lonRange.1 = mid
                }
            } else {
                let mid = (latRange.0 + latRange.1) / 2
                if latitude >= mid {
                    charIndex = charIndex | (1 << (4 - bit))
                    latRange.0 = mid
                } else {
                    latRange.1 = mid
                }
            }
            isEvenBit.toggle()
            bit += 1

            if bit == 5 {
                hash.append(base32[charIndex])
                bit = 0
                charIndex = 0
            }
        }
        return hash
    }

    static func neighborHashes(latitude: Double, longitude: Double, precision: Int = AppConstants.geoHashPrecision) -> [String] {
        let latStep = 180.0 / pow(2.0, Double(precision * 5 / 2))
        let lonStep = 360.0 / pow(2.0, Double((precision * 5 + 1) / 2))

        var hashes: [String] = []
        for dLat in [-latStep, 0, latStep] {
            for dLon in [-lonStep, 0, lonStep] {
                let hash = encode(latitude: latitude + dLat, longitude: longitude + dLon, precision: precision)
                if !hashes.contains(hash) {
                    hashes.append(hash)
                }
            }
        }
        return hashes
    }
}
