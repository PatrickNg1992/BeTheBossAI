# Unit Information Manager

The unit manager handles the units' status on the battlefield. It should be an autoloaded object. 

For each unit on the battlefield, whether defeated or not, it holds a *Unit Information* object to manage the status, including name, class, HP, Power, buffs, etc. The Unit Information object also points to the corresponding puck objects. A unit does not need to have exactly 1 puck. Some unit skills may create or hide pucks in the future. Creating and removing pucks should notify the manager.

Store a unit's puck-related physics information in the puck script, such as puck radius, mass, rotation, position and velocity. Other information should be stored in Unit Information objects. Details to be specified. 

When a unit takes damage in "Puck-puck time!" or Action Time, the damage is temporarily stored in the Unit Information as *Damage Stack*. The damage calculation and defeat checking should be delayed to Settle Timing. The Damage Stack should be displayed as hit count and a Ghost bar in the HP bar (HP trailing) before it is settled.

The Unit Information Manager works closely with the Unit Information board to display useful information to players. (Check ./unitInformationBoard.md)
