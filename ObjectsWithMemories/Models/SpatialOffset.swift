import simd

struct SpatialOffset {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var scale: SIMD3<Float>
}
