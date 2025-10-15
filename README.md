# Anti Long Knife Fix Plugin

## Description
The Anti Long Knife Fix plugin is a SourceMod plugin designed for Zombie Reloaded servers that prevents "long knife" exploits. This exploit allows zombie players to infect human players from unrealistic distances, which can ruin the gameplay experience. The plugin detects and blocks these illegitimate infections based on configurable distance limits.

## Author
SyntX34

## Why This Plugin Is Required
In Zombie Reloaded servers, players can sometimes exploit the knife infection mechanism to infect humans from distances that are not physically possible in normal gameplay. This creates an unfair advantage for zombie players and ruins the experience for human players. This plugin addresses this issue by:

1. Setting maximum distance limits for valid knife infections
2. Detecting when a zombie attempts to infect a human from beyond the allowed distance
3. Blocking these illegitimate infections while allowing normal gameplay
4. Providing configurable options for server administrators

## Features
- Configurable maximum distance for knife infections
- Multiple detection methods (player_hurt event, OnTakeDamage hook, or both)
- Integration with Zombie Reloaded's existing distance settings
- Debug mode for troubleshooting
- Detailed logging of blocked and allowed infections
- Minimal performance impact

## Installation
1. Download the [Plugin](plugin/longknifefix.smx) file.
2. Place the file in your server's `addons/sourcemod/plugins/` directory
3. Restart your server or reload plugins
4. Configure the plugin using the provided ConVars (optional)

## Configuration
The plugin creates several ConVars that can be adjusted in `cfg/sourcemod/antilongknife.cfg`:

- `sm_antilongknife_enable` (Default: 1) - Enable/disable the Anti Long Knife plugin
- `sm_antilongknife_maxdistance` (Default: 150) - Maximum allowed distance for knife infection (0 = disabled)
- `sm_antilongknife_fix` (Default: 1) - Enable/disable long knife fix
- `sm_antilongknife_method` (Default: 2) - Detection method (0 = player_hurt event, 1 = OnTakeDamage, 2 = both)
- `sm_antilongknife_debug` (Default: 0) - Enable debug messages
- `sm_antilongknife_use_zr_distance` (Default: 1) - Use zr_infect_max_distance if available, otherwise use plugin distance

## Requirements
- SourceMod 1.10 or higher
- MetaMod:Source
- Zombie Reloaded plugin
- Multicolors plugin (for colored chat messages)

## How It Works
The plugin monitors knife attacks in Zombie Reloaded games and calculates the distance between the attacker (zombie) and victim (human). If the distance exceeds the configured maximum, the infection is blocked and the victim's health is restored. The plugin uses both event-based and hook-based detection methods to ensure comprehensive coverage.

## Support
For issues, suggestions, or contributions, please contact the author or visit:
- GitHub: https://github.com/SyntX34
- Steam: https://steamcommunity.com/id/SyntX34