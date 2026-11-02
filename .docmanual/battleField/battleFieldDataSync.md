# Battlefield data sync

In multiplayer games, the data in battlefield scene should be synchronize from the host player to other players, including table players and spectators.

In single-player games, use the same logic for standardisation



The following lists how to handle different data in the battlefield scene: 

- Data to sync. For these data, only the host can manage them. Other players sync them from the host. The two players, who are not necessarily the host, sync the data from the host.
  
  - Boss monster stat: HP, Energy
  - Pucks positions
  - Action indicator data
  - Enemy and minion stats
  - Cards information
  - Timing information
  - Players’ completed action will notify the host to update

- Display based on data sync on players side
  
  - Time board display
  - The player’s hands (Only Player A and B)
  - pucks position
  - collision effects
  - Minion and enemy display

- Player self-own data
  
  - uncompleted action data
  - Data that controls player visibility
  - game config
