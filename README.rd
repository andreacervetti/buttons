# Buttons

A Button Mania game written in Ada

## Gameplay

The game presents a 6x6 grid of button with number from 0 to 3.
Clicking on a number that number and the four number surrounding it decrease by 1. If the value is 0 it is set to 3 again.
The objective of the game is to set all numbers to 0.
The game can be set to different level of difficulty.
Every level can be solved in a maximum number of moves that is <level number> * 3. So, level "Normal" (5) can be solved in 15 moves.

## Prerequisites

To compile the program you will need:
- An Ada 2005 compliant compiler.
- GtkAda 3.

Both can be dowloaded from [Adacore](https://www.adacore.com/community).

Under Linux or Freebsd you can use the packages that came with your distribution.


