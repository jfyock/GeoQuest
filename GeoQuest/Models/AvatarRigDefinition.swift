import Foundation

/// Bone name constants that GLB character models must use for skeletal animation.
/// These names are used by `GLBModelLoader` to validate rig structure and by
/// `AvatarSkeletonAnimator` to drive animations on specific joints.
enum AvatarRigDefinition {
    static let root = "root"
    static let hips = "hips"
    static let spine = "spine"
    static let chest = "chest"
    static let neck = "neck"
    static let head = "head"
    static let leftArm = "leftArm"
    static let rightArm = "rightArm"
    static let leftLeg = "leftLeg"
    static let rightLeg = "rightLeg"
    static let headTop = "headTop"
    static let noseBridge = "noseBridge"

    /// Minimum required bones for a valid rig.
    static let requiredBones: Set<String> = [
        root, hips, spine, head, leftArm, rightArm, leftLeg, rightLeg
    ]

    /// All known bones including optional ones.
    static let allBones: Set<String> = [
        root, hips, spine, chest, neck, head,
        leftArm, rightArm, leftLeg, rightLeg,
        headTop, noseBridge
    ]
}
