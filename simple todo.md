
- check floor and cushion logic
- change the logic to select block, build a location index when the game start, to allow faster calculation and special shape of table if necessary. the index use x,z position in integer (can assume all floor blocks are rectangle in the future)
- extra the standard friction calculation to a function in apply_ground_effect for easy customize
- puck puck time should be adopt the fast play
- make puck faster but decelerate faster as well
- cushion rebound logic, todo at 03
- after fall into pocket area, ...
- ensure sync data work