# WowAutoReview Addon

This repository will become a World of Warcraft addon that collects and persists character and guild data to disk.

Primary goals
- Collect structured data about characters and guilds (names, realms, classes, levels, membership, timestamps, etc.).
- Persist that data between sessions so it can be reviewed or exported later.

Recommended way to develop:  
- Clone this repository to your machine.  
- Create a symbolick link to your wow interface folder. (CMD with admin rights)  
  - ``mklink /D "WOW_RETAI_PATH_INTERFACE_ADDONS/WowAutoReview" "REPO_PATH/addon"``
    - For example: ``mklink /D "C:\BlizzardLibrary\World of Warcraft\_retail_\Interface\AddOns\WowAutoReview" "D:\_Dev\Github\WowAutoReview-Addon\addon"``