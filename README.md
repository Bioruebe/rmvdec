# rmvdec
A simple decrypter for RPG-Maker MV ressource files (.rpgmvp, .rpgmvo, rpgmvm)

### Usage
`rmvdec <input_file>|<input_dir> [<output_dir>] [-k <decryption_key>|<path_to_System.json>]`

- Rmvdec supports either a single file or a whole folder as input. In folder mode only files with one of the 3 allowed extensions is processed. Subdirectories are ++ignored++.
- The encryption/decryption key is needed to extract any file. It can either be specified directly or in form of the path to the games's System.json configuration file.
- If the 'key' argument is omitted, rmvdec automatically searches up to 5 levels upwards from the input directory for a data folder containing System.json. If the game folder structure is intact, this should always work.

### Technical details

RPG-Maker MV files are encrypted by simply XORing the raw bytes with a (probably random) key and adding a 16 byte header to the file. The file extension is based on the input type:
| encrypted | original |
| --------- | -------- |
| rpgmvp    | png      |
| rpgmvm    | m4a      |
| rpgmvo    | ogg      |

The encryption key is saved in System.json, which can be found inside the /data folder of the game.

### Remarks
Remember: don't steal assets from other people's games. Respect copyrights. And don't protect your own games - it's unnecessary effort.