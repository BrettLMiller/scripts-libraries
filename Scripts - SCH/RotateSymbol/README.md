# RotateSymbol Script

# DISCLAIMER
This script is provided "AS IS" in the hopes that it will be useful, but comes with no guarantees or warranties. Use of this script is conditional on accepting it as-is, and the user is responsible for any issues that may arise from its use, including failure to detect a critical problem that results in scrap boards. Please thoroughly verify its fitness for your particular use case.

## [DOWNLOAD](https://altium-designer-addons.github.io/DownGit/#/home?url=https://github.com/Altium-Designer-addons/scripts-libraries/tree/master/Scripts+-+SCH/RotateSymbol)

## What this script is
This script is a small utility to take a selection of components in the current schematic document and rotate or mirror the schematic symbol without repositioning the visible parameters.

## How to install and use
_Step 1_: [DOWNLOAD](https://altium-designer-addons.github.io/DownGit/#/home?url=https://github.com/Altium-Designer-addons/scripts-libraries/tree/master/Scripts%20-%20SCH/RotateSymbol) script

_Step 2_: integrate the script into Altium Designer and execute it.\
If you are a newcomer to Altium scripts, [please read the "how to" wiki page](https://github.com/Altium-Designer-addons/scripts-libraries/wiki/HowTo_execute_scripts).

## Usage guide
* Select schematic components and execute one of the script functions below. 
* In all cases, the visible parameters (and designator) should remain in their starting positions. 
* In the case of 2-pin symbols, library origin is ignored in favor of midpoint between the two hotspots. This allows use with 2-pin symbols that are not centered on the library origin.
* Non-component objects in selection are ignored.

## Functions
* ### _Mirror
Toggles the "Mirrored" property of the selected components.

* ### _RotateCCW
Rotates each selected component about its own origin by 90° counter-clockwise. This rotation is equivalent to selecting a single component and pressing SPACE.

* ### _RotateCW
Rotates each selected component about its own origin by 90° counter-clockwise. This rotation is equivalent to selecting a single component and pressing SHIFT+SPACE.

* ### About
Displays version info and directs user here.

* ### ReorientCCW - !!CAUTION!!
Updates the internal orientation of the selected components without actually rotating them. This should be used with caution because there is no external indicator that the symbol doesn't match the zero orientation of the source library. The only use I've identified for this so far is when the source library's symbol orientation is changed and you want to "correct" an already-placed component so that it doesn't rotate when updated from the libraries.

* ### ReorientCW - !!CAUTION!!
See previous function.

## Known Issues
* ### Rotates/Mirrors the symbol around the library origin, not the actual centroid. Symbols that are not symmetrical about symbol origin will behave accordingly.
  UPDATE: calculates actual hotspot centroid for 2-pin symbols

## Change log
- 2024-03-13 by Ryan Rutledge : v1.11 - added `About` info command
- 2024-03-13 by Ryan Rutledge : v1.10 - now rotates or mirrors about the part's true centroid (midpoint between electrical hotspots) for 2-pin symbols only
- 2024-03-12 by Ryan Rutledge : v1.00 - initial release
