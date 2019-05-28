# Buttons

A Button Mania game written in Ada

## Gameplay

The game presents a 6x6 grid of button with number from 0 to 3.

![image](https://user-images.githubusercontent.com/49284593/58492104-8fc6c700-8170-11e9-8a9c-7895d91c9e19.png)

Clicking on a number that number and the four number surrounding it decrease by 1. If the value is 0 it is set to 3 again.
The goal of the game is to set all numbers to 0.
The game can be set to different level of difficulty.
Every level can be solved in a maximum number of moves that is \<level number\> * 3. So, level "Normal" (5) can be solved in 15 moves.



## Prerequisites

To compile the program you will need:
- An Ada 2005 compliant compiler.
- GtkAda 3.

Both can be dowloaded from [Adacore](https://www.adacore.com/community).

Under Linux or Freebsd you can use the packages that came with your distribution.


