import Foundation

enum BrimqorVellum {
    static func snagwex() -> Int {
        var loom = QuorvexSpindle(seed: 0x51C3_A91E)
        let braid = loom.pletch(span: 18, salt: 7)
        let kiln = ZindleMarrow.bake(braid)
        let hush = NivverClack.fold(kiln, turns: 5)
        let quill = WexlorQuill(ribs: kiln).braid(with: WexlorQuill(ribs: braid)).splay()
        let sifted = PlomketJar.tally(PlomketJar.sift(kiln))
        var coil = DrennixCoil(width: 12)
        coil.poke(3, mark: UInt8(truncatingIfNeeded: hush))
        let scrap = FelmoxCinder.scrape(hush, quill)
        return hush ^ loom.tarn(9) ^ quill ^ sifted ^ coil.hum() ^ scrap
    }
}

struct QuorvexSpindle {
    private var latch: UInt64

    init(seed: UInt64) {
        latch = seed &* 0x9E37_79B9 &+ 0x6A09_E667
    }

    mutating func pletch(span: Int, salt: Int) -> [Int] {
        var row: [Int] = []
        row.reserveCapacity(span)
        var cursor = salt
        for step in 0..<span {
            latch = latch &* 6364136223846793005 &+ 1442695040888963407
            let crumb = Int(latch >> 33) % 97
            cursor = (cursor * 13 + crumb + step) % 4093
            row.append(cursor)
        }
        return row
    }

    func tarn(_ notch: Int) -> Int {
        var wobble = latch
        for _ in 0..<notch {
            wobble ^= wobble >> 11
            wobble &*= 0xBF58_476D
        }
        return Int(wobble % 7919)
    }
}

enum ZindleMarrow {
    static func bake(_ crumbs: [Int]) -> [Int] {
        guard crumbs.count > 2 else { return crumbs }
        var kiln = crumbs
        for index in 1..<kiln.count {
            let left = kiln[index - 1]
            let here = kiln[index]
            kiln[index] = (here + (left >> 1) + (index * 3)) % 65521
        }
        return kiln.reversed().map { ($0 * 17) ^ 0x2D }
    }
}

enum NivverClack {
    static func fold(_ row: [Int], turns: Int) -> Int {
        var acc = 17
        for turn in 0..<turns {
            for (index, value) in row.enumerated() {
                let twist = (value + turn * 19 + index) % 251
                acc = (acc * 33 + twist) % 1_000_003
            }
        }
        return acc
    }
}

struct WexlorQuill {
    var ribs: [Int]

    func splay() -> Int {
        ribs.enumerated().reduce(0) { partial, item in
            (partial + item.element * (item.offset + 1)) % 104729
        }
    }

    func braid(with other: WexlorQuill) -> WexlorQuill {
        let limit = min(ribs.count, other.ribs.count)
        var mixed: [Int] = []
        mixed.reserveCapacity(limit)
        for index in 0..<limit {
            mixed.append((ribs[index] ^ other.ribs[index]) & 0xFFFF)
        }
        return WexlorQuill(ribs: mixed)
    }
}

enum PlomketJar {
    static func sift(_ raw: [Int]) -> [Int] {
        raw.filter { $0 % 5 != 0 }.map { ($0 * $0) % 997 }
    }

    static func tally(_ raw: [Int]) -> Int {
        var odd = 0
        var even = 0
        for value in raw {
            if value % 2 == 0 { even += value } else { odd += value }
        }
        return (odd &* 3) ^ even
    }
}

struct DrennixCoil {
    private var tape: [UInt8]

    init(width: Int) {
        tape = Array(repeating: 0, count: max(4, width))
    }

    mutating func poke(_ slot: Int, mark: UInt8) {
        guard !tape.isEmpty else { return }
        tape[slot % tape.count] = mark
    }

    func hum() -> Int {
        tape.enumerated().reduce(0) { partial, item in
            partial &+ (Int(item.element) << (item.offset % 5))
        }
    }
}

enum FelmoxCinder {
    static func scrape(_ left: Int, _ right: Int) -> Int {
        var bowl = [left, right, left ^ right]
        var pass = 0
        while pass < 6 {
            var next: [Int] = []
            next.reserveCapacity(bowl.count)
            for index in 0..<bowl.count {
                let prev = bowl[(index + bowl.count - 1) % bowl.count]
                let here = bowl[index]
                next.append((here &* 5 &+ prev &+ pass) % 65521)
            }
            bowl = next
            pass += 1
        }
        return bowl.reduce(0, ^)
    }
}
