# Launchpad Binary Clock

A menu-bar app to turn Launchpad Mini MK3 into binary clock.
Requires macOS 13 or later.

## Outline

| Column | Field           | Color  |
| ------ | --------------- | ------ |
| 1      | Year, bits 0–7  | Red    |
| 2      | Year, bits 8–15 | Red    |
| 3      | Month           | Orange |
| 4      | Day             | Yellow |
| 5      | Blank separator | Off    |
| 6      | Hours, 0–23     | Green  |
| 7      | Minutes         | Blue   |
| 8      | Seconds         | Violet |

## Reading the time

For example, 13:42:25 lights these pads in the three rightmost columns.
Count rows from the bottom, with values 1, 2, 4, 8, 16, 32, 64, and 128.
Add the lit values in each column:

| Column           | Lit values | Total |
| ---------------- | ---------- | ----- |
| Hours (green)    | 8 + 4 + 1  | 13    |
| Minutes (blue)   | 32 + 8 + 2 | 42    |
| Seconds (violet) | 16 + 8 + 1 | 25    |

For the year, multiply the second column's value by 256 and add the first column.

## Provenance

Totes vibecoded. I wanted for Launchpad mini on my table to do something, so one-shoted this.

## Installation

Either grab binary from release or do `brew install --cask eiri/tap/lp-clock`.
