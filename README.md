# ![PosePal Icon](addons/posepal/plugin_icon.png) PosePal
PosePal is a Godot add-on by AniMesuro that allows storing a group of scene properties into Pose Librarys for use in 2D animation.
The project is a work in progress, so it may have bugs and it can crash Godot.

## Usage
- On the Parameters tab, click on poselib and select the owner of a scene. A poselib resource is created, but it will only save after changes are made to it.
- Select a filter. The default one is "none", which tracks all nodes inside the edited pose root.
- Select a template. The default is "default", which has no base properties.
- Select a collection. The default is "default", which stores poses.
- Clicking on New pose, you can key properties from different nodes so that they're stored into the pose.
- Click save. A new pose is created at the tab "Palette".
- Select an AnimationPlayer from the scene. Choose a time and click on the pose. It will key it on the animation.

## Pose Library
A Pose Library is a Resource bound to a scene that stores pose templates and collections.
Poselibs are bound to scenes by the meta variable "_plPoseLib_poseFile" in the scene root.
A poselib file will have the ".poselib.tres" or ".poselib.res" extension.

## Poses
Poses are records of data that store the state of a scene by storing selected properties. Usually used for character animation, but most kind of properties can be saved. (Unless tests are proven otherwise)

## Filter
Filters are a special kind of pose that do not stores values. These are used to filter only poses that change selected nodes from a filter.

## Templates
Templates are poses that are used as a base for all poses inside a collection. Therefore all poses created inside this template will copy the template's properties unless overwritten. A template can have duplicated template pose, but can't have a duplicated template name.

## Collections
Collections store poses directly. They're used to organize lots of poses.

## Pose Previews
These are thumbnail visualizations of the scene but overwritten by the pose. The generation of thumbnails is expensive because they need to instance a ghost version of the scene with only visual data (transforms, texture, z_index, etc.)

## Page System
Not working yet.

## Pose Options Tab
This tab should hold settings that could help managing poses. Currently it holds one button.

### Batch-key Pose
Keying properties for the pose is time consuming, so there is a shortcut to batch key all properties that have a track in the scene.
When you press the button on the Pose Options tab, you can select which nodes will key a written property.
The code for finding the user selected AnimationPlayer is dumb, so it's advisable to check the window title if it matches the Animation name.

## Godette Example Rig
GodetteRig is an example scene that comes bounded to a PoseLib. She has 8 directions: (Left, 3/4 Left, Front, 3/4 Right, Right, 3/4 Back Right, Back and 3/4 Back Left).
The PoseLib comes with default poses to demonstrate the add-on's basic capabilities.
Both the assets and the poselib is subject to change.

## Limitations:
- PosePal does not support 3D scenes, and bone animation.
- Changing the edited scene as you're diting a pose crashes Godot, so the Scene Tabs is invisible as you do so.
- Changing nodes names and nodepaths will confuse the poselib.
- Changing resources (Images)'s paths will confuse the poselib.

The add-on is not very stable, so it's advisable not use in production.