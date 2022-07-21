# Project Arkanoid

## WIP
### The project is under development, the main menu is missing, it has some collision and audio bug, also aliens and some power ups effects are missing

This projects aims to replicate the old Arkanoid arcade game dated 1986!
The sound effects and the sprites are from the original game, and took from here https://www.spriters-resource.com/arcade/arkanoid/

## The game

Actually the game should work on all supported platforms, although is designed for mobile nad some components still missing correct scaling.
Currently only the first five levels are available

To install it is simple:
Install the Flutter SDK, open the project with you preferred IDE (VS Code is recommended), run the command __flutter pub run build_runner build__,  select the platform and run it!

## The level editor

This project also comes with a levels editor that is supported only on browser.
It is still in an early stage and not so user friendly but it's working.

To launch it open the **level_editor.dart** file inside level_editor folder and press **Run** that's is above the **void main** function (probably the Run is availble only in VS Code). 

To use it:
Use the right column to select the color and/or the power up of the brick; then press the button below "Set on brick".
If a brick is clicked, the previous selection is set on it.
If you want to modify multiple brick, just right click and hover on bricks; right click again to stop hover modification.

The button below the brick [...] let you select the level number and the background.

When you are ready and your level is completed, press the button "Generate Code".
The generated file can be added to the game just by moving the file to **levels** folder and modifying **main.dart**.


Game components:

- Starship
    - Power ups
    - Lives
    - Size
    - Speed
    - Movement

- Ball
    - Speed
    - Direction
    - Hitting moving starship change ball direction

- Power ups
    - Glue
    - Laser (if a laser touch an unbreakable block, the other one is stopped)
    - Life
    - Points
    - Ball lower speed
    - Triple balls
    - Taking a power up invalidate the previous one


- Blocks
    - Breakable 1 hit(blue,red,yellow,green,light blue, pink, white)
    - Breakable 4 hits (grey)
    - Unbreakable (gold)
    - Has power up

- Field
    - Size
    - Background


- Aliens
    - Destroy on ball or starship hit
    - Change ball direction like blocks

- Boss
    - The Great DOH 
