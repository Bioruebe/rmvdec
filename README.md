# rmvdec

A simple decrypter for RPG-Maker MV resource files (.rpgmvp, .rpgmvo, rpgmvm)

### Usage

`rmvdec <input_file>|<input_dir> [<output_dir>] [-r] [-rm] [-k <decryption_key>|<path_to_System.json>]`

- Rmvdec supports either a single file or a whole folder as input. In folder mode only files with one of the 3 allowed extensions is processed. Subdirectories are ignored per default.
- The encryption/decryption key is needed to extract any file.
  - It can either be specified directly or in form of the path to the games's System.json configuration file.
  - If the 'key' argument is omitted, rmvdec automatically searches up to 5 levels upwards from the input directory for a data folder containing System.json. If the game folder structure is intact, this should always work.

#### Options

| Switch | Alternative switches       | Description                                                      |
| ------ | -------------------------- | ---------------------------------------------------------------- |
| -r     | `--recursive`, `--recurse` | Include files in subdirectories                                  |
| -rm    | `--remove`                 | Delete original files after decryption                           |
| -f     | `--force`                  | Try to decrypt all files, not only those with allowed extensions |

### Technical details

RPG-Maker MV files are encrypted by simply XORing the raw bytes with an encryption key and adding a 16 byte header to the file. The key is saved in System.json, which can be found inside the `/data` folder of the game. The file extension is based on the input type:

| encrypted | original |
| --------- | -------- |
| rpgmvp¹   | png      |
| rpgmvm    | m4a      |
| rpgmvo    | ogg      |

¹ Some games use `.png_` as an extension for images instead. Rmvdec checks for this extension as well.

### Remarks

No reverse engineering has been used to write this tool, it is based on public information about the file format released by other researchers.

I released it as a helper for artists to search games for unlicensed use of their assets. It is not meant to encourage extraction with the sole purpose of using assets in your own products without permission of the copyright holder.

Remember: don't steal assets from other people's games. Respect copyrights. And don't protect your own games - it's unnecessary effort.