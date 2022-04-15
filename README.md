# ![posepal Logo](https://images2.imgbox.com/9d/53/qxG5RAKa_o.png)
posepal is a Godot add-on by AniMesuro that allows storing a collection of scene properties into Pose Libraries for use in 2D animation.
The project is close to its first release, but's still a work in progress.

## Installation
posepal is still in development, so you can only install it from the github page.
There's no stable release yet, so either clone it or download as a zip file and paste it on `res://addons/` of your project.

## Demo Video
[![hey](https://img.youtube.com/vi/1trtx8Bv6hw/hqdefault.jpg)](https://www.youtube.com/watch?v=1trtx8Bv6hw)

## Getting Started
- On the Parameters tab, click on poselib and select the owner of a scene. A poselib resource is created, but it will only save after changes are made to it (unless you save it manually).
- Select a filter. The default one is "none", which tracks all nodes inside the edited pose root.
- Select a template. The default is "default", which stores collections.
- Select a collection. The default is "default", which stores poses.
- Clicking on New pose, you can key properties from different nodes into an Animation so that they're stored into the pose.
- Click save. A new pose is created at the tab "Palette".
- Select an AnimationPlayer from the scene. Choose a time and click on the pose preview. It will key it on the selected animation.


[If you want to know more, there's a wiki.](https://github.com/AniMesuro/posepal/wiki)


### Recommended Practices
Key template checkbox makes so you pose exactly as in the preview.
Don't key on duplicates checkbox makes the keying more readable as it only keys on change.
Queue key is a useful button to remove the need to fix the previous keys when keying a pose.


[There's a page for more practices.](https://github.com/AniMesuro/posepal/wiki/Recommended-Practices.)

### Godette Example Rig
GodetteRig is an example scene that comes bounded to a PoseLib. She has a template for 8 directions: (Left, 3/4 Left, Front, 3/4 Right, Right, 3/4 Back Right, Back and 3/4 Back Left).
The PoseLib comes with default poses to demonstrate the add-on's basic capabilities.
Both the assets and the poselib is subject to change.
Her files are found on `res://addons/posepal/_example_rig_godette/`
<img src=https://images2.imgbox.com/59/41/6rC3QnnF_o.png width = 500>

## Pose Library
A Pose Library is a Resource bound to a scene that stores pose templates and collections.
Poselibs are bound to scenes by the meta variable "_plPoseLib_poseFile" in the scene root.
Although you can save poselibs separately, you shouldn't try to open a poselib for a different scene than the original because there's a chance of corrupting the poselib.  
A poselib file will by default be saved at the scene directory and will have the ".poselib.tres" or ".poselib.res" extension, by the choice of the user.\
<img src=https://images2.imgbox.com/98/88/CS3HrUc4_o.png >
## Pose
Pose is a record of data that stores the state of a scene by storing selected properties. Usually used for character animation, but most kind of properties can be saved. (Unless tests are proven otherwise)
Pose editing is done through the AnimationTimelineEditor in Godot, by keying desired properties at the current time

## Filter
Filter is a selection of nodes.
This is used to filter poses to change only selected nodes from a filter.
It can be edited by pressing 'Edit' on its options. In the popup you select which nodes the filter should select.
## Templates
Templates are poses that are used as a base for all poses inside a collection. Therefore all poses created inside this template will copy the template's properties unless overwritten. A template can have duplicated template pose, but can't have a duplicated template name.
A template also stores transition and update mode, but for a pose to inherit this data it's necessary to click the "Update from template" button.
To key a template when pressing a pose you can select the 'key template' CheckBox.

## Collections
Collections store poses directly. They're used to organize lots of poses.

## Pose Previews
These are thumbnail visualizations of the scene but overriden by the pose. The generation of thumbnails is expensive because they need to instance a ghost version of the scene with only visual data (transforms, texture, z_index, etc.)

### Batch-key Popup
Keying properties for the pose is time consuming, so there is a shortcut to batch key all properties that have a track in the scene.
When you press the button on the Pose Options tab, you can select which nodes will key a written property.
The code for finding the user selected AnimationPlayer is dumb, so it's advisable to check the window title if it matches the Animation name.\
<img src=https://images2.imgbox.com/32/e2/eUkSS720_o.png width=600>

## Skeleton Support
posepal kind of supports skeleton posing, although with some quirks.
You shouldn't key the polygon data when editing a pose, posepal does it automatically when you key  the polygon 'texture' and save the pose.
The previews are in a different level though, polygons don't seem to be able to bound with a skeleton by code, so a workaround is necessary: you need the calibrate the bones by selecting the scene option "Setup bones" and associating the bone and polygon relationship. The results are less than ideal, but give a crude idea of the pose's gist if the rig is somewhat basic.
If you want to see the skeleton for the scene for readability you can select 'Show bones' in the preview pose options.

## Limitations:
- posepal does not support 3D scenes.
- posepal supports skeleton poses, but not previewing them. A workaround is to make polygons copy the bone's transform, but it looks gross.
- Changing the edited scene as you're editing a pose crashes Godot, so the Scene Tabs is invisible as you do so.
- Changing nodes names and nodepaths may make the poselib unusable.
- Changing resources (Images)'s paths will confuse the poselib. You'll need to fix the dependencies manually.

The add-on is not very stable, so it's advisable not use in production.
Making backups is always advisable, but you'd need to copy the files manually.

## Support:
If you like this project, I'd greatly appreciate a donation. </p>
[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/V7V82FBZH)
