
- check floor and cushion logic
- change the logic to select block, build a location index when the game start, to allow faster calculation and special shape of table if necessary. the index use x,z position in integer (can assume all floor blocks are rectangle in the future)
- puck puck time should be adopt the fast play. create functions to apply impulse and force to pucks. Also for calculate position. the fast play ratio should affect the logic that applying force and position. also make the default friction deceleration faster, change from 1/s^2 to 1.2
- extra the standard friction calculation to a function in apply_ground_effect for easy customize
- make puck faster but decelerate faster as well
- cushion rebound logic, todo at 03
- after fall into pocket area, ...
- ensure sync data work