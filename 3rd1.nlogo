breed [ cells cell ] ;create cells
breed [ Ls L ] ;create Ls
breed [ trailers trailer ] ;create trailers
undirected-link-breed [ adhesions adhesion ]
undirected-link-breed [ trailerLines trailerLine ]

cells-own
[ A B C cycle phase mu released? trailerColor ]
patches-own
[ conc-cells conc-L ]

globals [
  ;Enviornmental
  cell-count L-count assay-size initial-density dt g1-count s-count m-count g2-count %S cycle-time

  variability

  ;Cells
  resp-A resp-B resp-C resp-ave resp-max colorControl

  ;L1
  mu-L prolif-factor

  ;Control
  searching xx yy colorList

  ;Phase Changes
  g1 s m g2
]

to setup
  clear-all
  set-default-shape cells "perfectcell"
  set-default-shape Ls "dot2"
  set-default-shape trailers "dot2"


initialize
end

to initialize
  reset-ticks

  ;Enviornmental
  set cell-count 17 * abs (min-pxcor - scratch-line) ;make constraints
  set assay-size (max-pycor - min-pycor) * (scratch-line - min-pxcor)
  set initial-density (cell-count / assay-size)
  set dt .23 ;time-based variable

  ;Cells
  set resp-A ( 1 - 0.01 * A-inhibition ) ;pathway responses
  set resp-B ( 1 - 0.01 * B-inhibition )
  set resp-C ( 1 - 0.01 * C-inhibition )
  set resp-ave mean (list resp-A resp-B resp-C)
  set resp-max min (list resp-A resp-B resp-C)


  set %S %_in_S-phase_Base - ( 1 - resp-max ) * ( %_in_S-phase_Base - %_in_S-phase_Max_Inhibition )

  set colorControl 5

  ;Ligand (L1CAM)
  set mu-L LigandSpeed

  ifelse (resp-ave != 0)
  [ set prolif-factor 1 / resp-ave ]
  [ set prolif-factor 110 ]
  set variability deviation-from-avg

set cycle-time int doubling-time * 60

ifelse (S-phase_to_G1?) [
  set g1 int ( cycle-time * ( .79 - %S / 100 ))
  set s g1 + int ( cycle-time * %S / 100 )
  set m s + 1
  set g2 cycle-time
]
[
  set g1 int ( cycle-time * .46)
  set s g1 + int ( cycle-time * %S / 100 )
  set m s + 1
  set g2 cycle-time
]

;  set g1 int prolif-factor * int doubling-time * int (54 - %S / 100 * 60) ;corrections to time scale
;  set s int prolif-factor * int doubling-time * 54
;  set m int prolif-factor * int doubling-time * 55
;  set g2 int prolif-factor * int doubling-time * 60

  populate
  make-scratch


end

to populate ;add cells behind scratch line
  create-cells cell-count [
    update-density
    set searching true
    while [ searching ] [
      set xx scratch-line + random-float (min-pxcor - scratch-line)
      set yy min-pycor + random-float (max-pycor - min-pycor)

      if not any? cells-at xx yy [
        setxy xx yy
        set searching false ]]

    set A ( Base_Motility_A + ( UninhibitedMotility - Base_Motility_A ) * ( 1 - 0.01 * A-inhibition))
    set B ( Base_Motility_B + ( UninhibitedMotility - Base_Motility_B ) * ( 1 - 0.01 * B-inhibition))
    ifelse ( min ( list A B ) * ( 1 - 0.01 * C-inhibition ) > Base_Motility_C )
    [ set C ( min ( list A B ) * ( 1 - 0.01 * C-inhibition ) ) ]
    [ set C Base_Motility_C ]

    ifelse (random-float 1 < 0.5)
    [ set mu C + random-float variability ]
    [ set mu C - random-float variability ]

if (motility-check?) [
    if ( mu < 0) [
    set mu 0
    ]
]

    set color blue
    set released? false
    set cycle random cycle-time ;cells are randomly assigned a cycle to begin
    ]
end

to make-scratch ;creates green cells on scratch line
  ask cells [
    if xcor >= scratch-line - 1 [
      if any? cells-here [
        set color green
        set released? true
        set trailerColor colorControl
        set colorControl (colorControl + 10)
        hatch-Ls 2 + random-float 4 [ set color yellow ]
        ]
    ]
  ]
  ask patches [
    if show-scratch? [
      if pxcor = scratch-line - 1 [
        set pcolor white ;show scratch line
      ]
    ]
  ]
end

to go
  set cell-count count cells
  set L-count count Ls
  if cell-count <= 0 [ stop ] ;can't have negative cells

  ;set phases
;  set g1 int prolif-factor * int doubling-time * int (54 - %S / 100 * 60) ;corrections to time scale
;  set s int prolif-factor * int doubling-time * 54
;  set m int prolif-factor * int doubling-time * 55
;  set g2 int prolif-factor * int doubling-time * 60
  ask patches [ update-density ]
  ask cells [
    update-params
    cell-diffuse
    L-production
  ]
  ask Ls [
    L-diffuse ;show Ls while running
    ifelse show-L? ;shows Ls
    [ set hidden? false ]
    [ set hidden? true ]
  ]
  tick
  if (ticks >= 60 * time-scale) [ stop ] ;ends after time scale is reached
end

to update-density ;calculates density
  ifelse (any? cells-here)
  [ set conc-cells count cells-here ]
  [ set conc-cells 0 ]

  set conc-L sum [ count Ls-here ] of neighbors / 8
end

to update-params

      if (cellular-adhesion) [
      let unscratched cells-on neighbors
      create-adhesions-with unscratched with [color = blue]]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;                       ;;
  ;; LINK LENGTH FOR DEATH ;;
  ;;                       ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;

  if (cellular-adhesion) [
    ask links

    ;;;;;;;;;;;;;;;;;;;;;;;
    ;; HERE SPECIFICALLY ;;
    ;;;;;;;;;;;;;;;;;;;;;;;

    [ if link-length > 2 [ die ]]

    let t (turtle-set cells with [ color = blue ])

    ;;;;;;;;;;;;;;;;;;;
    ;; LAYOUT PARAMS ;;
    ;;;;;;;;;;;;;;;;;;;

    layout-spring t adhesions 0.0001 0.01 0.0001 ]

  ifelse (released?)
  [
    if (color = blue) [ set color red ]
    if (color = blue + 2) [ set color orange ]

    set A (( Base_Motility_A + ( UninhibitedMotility - Base_Motility_A ) * ( 1 - 0.01 * A-inhibition) + A ) / 2 )
    set B (( Base_Motility_B + ( UninhibitedMotility - Base_Motility_B ) * ( 1 - 0.01 * B-inhibition) + B ) / 2 )
    ifelse ( min ( list A B ) * ( 1 - 0.01 * C-inhibition ) > Base_Motility_C )
    [ set C ( min ( list A B ) * ( 1 - 0.01 * C-inhibition ) ) ]
    [ set C Base_Motility_C ]

    ifelse (random-float 1 < 0.5)
    [ set mu C + random-float variability ]
    [ set mu C - random-float variability ]

if (motility-check?) [
    if ( mu < 0) [
    set mu 0
    ]
]

    ifelse (cycle < cycle-time) ;updates cell cycle
      [ set cycle cycle + 1 ]
      [ set cycle 0 ]
    update-phase
  ]
  [

    set A ( Base_Motility_A + ( UninhibitedMotility - Base_Motility_A ) * ( 1 - 0.01 * A-inhibition))
    set B ( Base_Motility_B + ( UninhibitedMotility - Base_Motility_B ) * ( 1 - 0.01 * B-inhibition))
    ifelse ( min ( list A B ) * ( 1 - 0.01 * C-inhibition ) > Base_Motility_C )
    [ set C ( min ( list A B ) * ( 1 - 0.01 * C-inhibition ) ) ]
    [ set C Base_Motility_C ]

    ifelse (random-float 1 < 0.5)
    [ set mu C + random-float variability ]
    [ set mu C - random-float variability ]

if (motility-check?) [
    if ( mu < 0) [
    set mu 0
    ]
]

    ifelse (cycle < cycle-time) ;updates cell cycle
      [ set cycle cycle + 1 ]
      [ set cycle 0 ]
    update-phase

  ]

;ifelse (resp-ave != 0)
;[ set prolif-factor 1 / resp-ave ]
;[ set prolif-factor 110 ]

  ask cells [
    if (color = green) or (color = red) [
      ask my-links [die]
    ]
  ]

  if (trailers?) [
    if (color = green) [
      hatch-trailers 1 [
        set color [trailerColor] of myself

      ]
    ]
  ]

end

to update-phase ;assigns phase number to cells in a cycle

  if (0 <= cycle) and (cycle < g1) [ set phase 0 ]
  if (g1 <= cycle) and (cycle < s) [ set phase 1 ]
  if (m = cycle) [ set phase 2 ]
  if (m < cycle) and (cycle < g2) [ set phase 3 ]

  if (phase = 2) [ mitosis ]

end


to mitosis ;creates two new cells from cell in mitosis phase
  let empty-patches neighbors with [ conc-cells < initial-density ]
  if any? empty-patches
  [
    hatch-cells 1 [
      if (color = green) [set color lime + 2] ;changes color of newly created cells
      if (color = red) [set color orange]
      if (color = blue) [set color blue + 2]
      fd 1
      ]
  ]

end

to cell-diffuse
  let empty-patches neighbors with [ conc-cells < initial-density ]

  if any? empty-patches ; allows diffusion of cells into empty space
  [

    if ( xcor > (min-pxcor + 1) )
    [ if ( [ conc-cells ] of patch-at-heading-and-distance 270 1 > 2 )
      [ set heading 90
        fd sqrt(2) * mu * dt ]] ;distance cell moves forward

    ifelse (random-float 1 < randomness)
    [

      ifelse (random-float 1 < 0.5)
          [ set heading 90
            fd sqrt (2) * mu * dt]
          [ set heading 270
            fd sqrt (2) * mu * dt]
          ifelse (random-float 1 < 0.5)
          [ set heading 0
            fd sqrt (2) * mu * dt]
          [ set heading 180
            fd sqrt (2) * mu * dt]

      ]

    [

      face min-one-of neighbors [conc-cells]
      fd sqrt (2) * mu * dt

      ]

  ]
end

to L-production

  ifelse (xcor >= scratch-line) and ([conc-cells] of patch-at-heading-and-distance 90 1 < 2) [
    if (random-float 1 < 0.05) [
      hatch-Ls random-float 4 [ set color yellow ]
      set released? true ]] ;hatches Ls if concentration is low
  [
    if (xcor < scratch-line)
    [if (color = red) [
    set color blue]]
    if (color = orange) [
      set color blue + 2]
    if (color = blue) or (color = blue + 2) [
      set released? false
    ]]

  if (xcor >= scratch-line) [
    if (color = blue) [set color red]
    if (color = blue + 2) [set color orange]
]


end

to L-diffuse ;how Ls move
  ifelse (random-float 1 < L-randomness) [
    ifelse (random-float 1 < 0.52)
      [ set heading 90
        fd mu-L ]
      [ set heading 270
        fd mu-L ]
    ifelse (random-float 1 < 0.5)
      [ set heading 0
        fd mu-L ]
      [ set heading 180
        fd mu-L ]
  ]
  [
    ifelse (any? cells-on neighbors) [
      face one-of cells-on neighbors
      fd mu-L
    ]
    [
    face one-of cells with [color = blue]
    fd mu-L
    ]
  ]

  if (random-float 1 < .005) ;99.5% chance of L death
    [ die ]

end

to clear-cells ;option to clear cells to see trailers
    ask cells [
       set hidden? true
    ]
end

to show-cells ;option to show cells after they have been cleared
    ask cells [
      set hidden? false
    ]
end

to-report time
  let hours  int (ticks / 60)
  let minutes ticks - hours * 60
  report ( list hours ":" minutes )
end

to-report mean-mu
  report mean [mu] of cells with [color = green]
end

to-report s-phase
  set s-count count cells with [ phase = 1 ]
  report 100 * s-count / cell-count
end

to-report g1-phase
  set g1-count count cells with [ phase = 0 ]
  report 100 * g1-count / cell-count
end

to-report g2-phase
  set g2-count count cells with [ phase = 3 ]
  report 100 * g2-count / cell-count
end

to-report m-phase
  set m-count count cells with [ phase = 2 ]
  report 100 * m-count / cell-count
end

to-report cleaved-cells
  let initial-count-cl count cells with [color = green]
  let released-count-cl count cells with [color = red]
  let initial-count-2-cl count cells with [color = lime + 2]
  let released-count-2-cl count cells with [color = orange]
  report (initial-count-cl + released-count-cl + initial-count-2-cl + released-count-2-cl)
end

to-report uncleaved-cells
  let initial-count count cells with [color = blue]
  let released-count count cells with [color = blue + 2]
  report (initial-count + released-count)
end

to-report total-cells
  report count cells
end

to-report %Sphase
  report %S
end

to motilityGraph
   if any? cells with [ color = green ] [plotxy ticks / 60 mean [mu] of cells with [ color = green ]]
end
@#$#@#$#@
GRAPHICS-WINDOW
175
10
1118
292
-1
-1
14.385
1
10
1
1
1
0
0
0
1
-32
32
-9
9
1
1
1
ticks
30.0

BUTTON
6
11
88
44
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
89
11
175
44
Run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
115
625
315
658
A-inhibition
A-inhibition
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
115
659
315
692
B-inhibition
B-inhibition
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
115
693
315
726
C-inhibition
C-inhibition
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
175
300
1120
333
scratch-line
scratch-line
min-pxcor
max-pxcor
-12.0
1
1
NIL
HORIZONTAL

SLIDER
5
90
174
123
time-scale
time-scale
1
72
24.0
1
1
hours
HORIZONTAL

SLIDER
5
215
174
248
randomness
randomness
0
1
0.1
0.01
1
NIL
HORIZONTAL

MONITOR
287
470
382
515
Avg Motility
mean-mu
3
1
11

MONITOR
111
515
201
560
% in S-phase
s-phase
2
1
11

MONITOR
10
470
85
515
Ligand Count
count Ls
17
1
11

MONITOR
285
515
381
560
Uncleaved Cells
uncleaved-cells
17
1
11

MONITOR
206
515
286
560
Cleaved Cells
cleaved-cells
17
1
11

PLOT
382
348
690
561
Average Motility of Green Cells
Time (hours)
mu (micrometers/min)
0.0
18.0
0.0
0.5
true
false
"set-plot-x-range 0 time-scale" ""
PENS
"pen-3" 1.0 0 -10899396 true "" "if any? cells with [ color = green ] [plotxy ticks / 60 mean [mu] of cells with [ color = green ]]"
"pen-1" 1.0 0 -16777216 true "" "plotxy ticks / 60 0"

PLOT
692
564
1122
749
Phase Cycle
Time (minutes)
% of cells
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"G1" 1.0 0 -13345367 true "" "if any? cells [ plot g1-phase ]"
"S" 1.0 0 -2674135 true "" "if any? cells [ plot s-phase ]"
"G2" 1.0 0 -10899396 true "" "if any? cells [ plot g2-phase ]"
"M" 1.0 0 -7500403 true "" "if any? cells [ plot m-phase ]"

PLOT
691
348
1121
561
Cell Count
Time (minutes)
Number of cells
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Initial Cell, Adhesed" 1.0 0 -13345367 true "" "plot count cells with [color = blue]"
"Daughter Cell, Adhesed" 1.0 0 -8020277 true "" "plot count cells with [color = blue + 2]"
"Initial Blue Cell, L e+" 1.0 0 -2674135 true "" "plot count cells with [color = red]"
"Initial Cell, L e+" 1.0 0 -10899396 true "" "plot count cells with [color = green]"
"Green Daughter Cell, L e+" 1.0 0 -8330359 true "" "plot count cells with [color = lime + 2]"
"Red Daughter Cell, L e+" 1.0 0 -955883 true "" "plot count cells with [color = orange]"
"Overall Count" 1.0 0 -16777216 true "" "plot count cells"

SWITCH
5
50
174
83
cellular-adhesion
cellular-adhesion
1
1
-1000

PLOT
385
565
690
750
Phase Histogram
G1         -         S         -         M         -         G2
Number of cells
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ phase ] of cells"

MONITOR
205
470
288
515
Cell Count
count cells
17
1
11

MONITOR
87
470
202
515
Time (hours:minutes)
time
17
1
11

INPUTBOX
115
410
195
470
doubling-time
24.0
1
0
Number

INPUTBOX
195
410
275
470
LigandSpeed
0.25
1
0
Number

MONITOR
10
515
110
560
theo. % S-phase
%Sphase
2
1
11

INPUTBOX
5
565
100
625
Base_Motility_A
0.13
1
0
Number

INPUTBOX
5
625
100
685
Base_Motility_B
0.15
1
0
Number

INPUTBOX
5
410
115
470
%_in_S-phase_Base
28.0
1
0
Number

INPUTBOX
100
565
260
625
%_in_S-phase_Max_Inhibition
8.0
1
0
Number

SWITCH
5
335
174
368
trailers?
trailers?
1
1
-1000

SLIDER
5
255
174
288
L-randomness
L-randomness
0
1
0.95
.01
1
NIL
HORIZONTAL

INPUTBOX
275
350
380
410
UninhibitedMotility
0.23
1
0
Number

TEXTBOX
121
730
311
763
These sliders allow us to control the amount of inhibition to apply to a particular pathway.
9
0.0
1

SWITCH
5
295
174
328
show-L?
show-L?
0
1
-1000

INPUTBOX
275
410
380
470
deviation-from-avg
0.3
1
0
Number

SWITCH
5
175
175
208
show-scratch?
show-scratch?
1
1
-1000

BUTTON
5
130
90
163
clear-cells
clear-cells
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
90
130
175
163
show-cells
show-cells
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
5
685
100
745
Base_Motility_C
0.12
1
0
Number

SWITCH
5
375
140
408
motility-check?
motility-check?
1
1
-1000

SWITCH
135
375
275
408
S-phase_to_G1?
S-phase_to_G1?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

A simple and accurate rule-based model for autocrine/paracrine stimulation of glioblastoma cell motility and proliferation by L1CAM in 2-D culture

## HOW IT WORKS

In the model L1CAM is released by cells to act through two cell surface receptors and a point of signaling convergence to increase cell motility and proliferation.  A simple graphical interface is provided so that changes can be made easily to several parameters controlling cell behavior, and behavior of the cells is viewed both pictorially and with dedicated graphs.

## HOW TO USE IT

Setup cells and scratch line, using various options to visulaize trailers, the scratch line, the Ls, and the cells themselves. Adjust options to describe movement of cells, as well as the option to inhibit the pathways that stimulate the cells.

## THINGS TO NOTICE

Notice the randomized behavior of the cells and the Ls, as well as the changes in motility of the scratch edge. The phases of each cells are plotted (one for the current time and one recording the change over time), so be aware of how cells are going through the cell cycle.

## THINGS TO TRY

Try to adjust the inhibition sliders to observe the effect that inhibiting one or more pathway(s) has on cell motility and permeation. (See paper for diagram of cell pathway)
Also try turning on cellular adhesion and view thw interconnections between blue cells, but not green cells.  However, this drastically slows down the simulation unless the scratch edge is moved to the left to approximately 10% of its range.  

## EXTENDING THE MODEL

Attempts to improve the model include, but are not limited to:
-Adapting this to a 3D model
-Allowing for stimulated cells to move through the cell cycle faster
-Addition of a second scratch to the right of the model, possibly releasing a protein that can stimulate the cells on the other side
-Adapting this to scratch assays of other cell types

## NETLOGO FEATURES

Random movement, ability to model cell cycle/phases


## CREDITS AND REFERENCES

Justin Caccavale (1), David Fiumara (1), Michael Stapff (2), Liedeke Schweitzer (2), Amy Nelson (1), Hannah J. Anderson (3), Prasad Dhurjati (1,2,3), and Deni S. Galileo (3,4)

(1) Department of Chemical and Biomolecular Engineering, (2) Department of Mathematical Sciences, (3) Department of Biological Sciences, University of Delaware, Newark, DE, (4) Helen F. Graham Cancer Center and Research Institute, Christiana Care Health System, Newark, DE
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

ballpin
false
0
Polygon -1 true false 150 135 150 150 165 150 255 60 240 45 150 135
Circle -7500403 true true 181 31 86

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

cell
true
0
Polygon -7500403 true true 150 0 45 45 0 150 45 255 150 300 255 255 300 150 255 45 150 0
Circle -1 false false 30 30 240
Circle -5825686 true false 129 129 42

checker piece 2
false
0
Circle -7500403 true true 60 60 180
Circle -16777216 false false 60 60 180
Circle -7500403 true true 75 45 180
Circle -16777216 false false 83 36 180
Circle -7500403 true true 105 15 180
Circle -16777216 false false 105 15 180

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

circleborder
false
0
Circle -7500403 true true 0 0 300
Circle -1 false false 15 15 270

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 135 135 30

dot2
true
0
Circle -7500403 false true 129 129 42

dot3
true
0
Circle -1 false false 120 120 58
Circle -8630108 true false 129 129 42

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

perfectcell
false
10
Polygon -1184463 true false 285 150 180 15 15 60 15 240 180 285
Polygon -13345367 true true 283 150 180 30 17 65 16 238 180 270
Circle -5825686 true false 101 116 67

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
