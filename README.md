# PostuRecord
PostuRecord is a Godot add-on by AniMesuro that allows storing a group of scene properties into a pose, managing a Pose Library for using in animation.

## Pose Library
A Pose Library is a Resource bound to a scene that stores pose templates and collections.
Poselibs are bound to scenes by the meta variable "_plPoseLib_poseFile" in the scene root.
A poselib file will have the ".poselib.tres" or ".poselib.res" extension.

## Poses
Poses are records of data that store the state of a scene by storing selected properties. Usually used for character animation, but any kind of property can be saved.

## Filter Pose
Filter Poses are a special kind of pose that does not stores values. These are used to filter only poses that change selected nodes.
Filter poses are also used as a template when the pose is created. The properties are gotten from the filter pose, but the values get overwritten by the scene node's current property.

## Templates
Templates are poses that are used as a base for all poses inside a collection. Therefore all poses created inside this template will copy the template's properties unless overwritten. A template can have dupplicated template pose, but can't have a dupplucated template name.

## Collections
Collections store poses

Collections store subcollections and Subcollections store poses.
This design is made to incentivize users to categorize their poses as much as possible.

## Pose Previews
These are thumbnail visualizations of the scene but overtwritten by the pose. The generation of thumbnails is expensive because they need to instance a ghost version of the scene with only visual data (transforms, texture, z_index)

## Page System
The page system is made to optimize pose thumbnail generation. Previews are costly to generate, so the palette is limited to show only 9 per page.

## Bake/Write/Batch-key Pose
Keying properties for the pose is time consuming, so there is a shortcut to batch key all properties that have a track in the scene.

-- Maybe it'd be more useful as a separate plugin 

## Godette Example Rig
GodetteRig is an example scene that comes bounded to a PoseLib. She has 3 directions: (Left, 3/4 Left and Front).
The PoseLib comes with default poses to demonstrate the add-on's capabilities.

## Limitations:
PosePal does not support 3D scenes, and bone animation.