package;

import haxe.Json;
import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author Bioruebe
 */
class Main {
	private static inline var HEADER_LENGTH  = 16;
	private static inline var ACTION_RENAME = 2;
	private static var files:Array<String>;
	private static var validExtensions = ["rpgmvp" => ".png", "rpgmvm" => ".m4a", "rpgmvo" => ".ogg"];
	
	static function main() {
		Bio.Header("rmvdec", "1.2.0", "2018-2019", "A simple decrypter for RPG-Maker-MV ressource files (.rpgmvp, .rpgmvo, rpgmvm)", "<input_file>|<input_dir> [<output_dir>] [-rm] [-k <decryption_key>|<path_to_System.json>]");
		Bio.Seperator();
		
		var args = Sys.args();
		if (args.length < 1) Bio.Error("Please specify an input path. This can either be a file or a directory containing RPG-Maker-MV ressource files.", 1);
		
		files = readInputFileArgument(args[0]);
		var keyArgPos = args.indexOf("-k");
		var deleteOriginalFiles = args.indexOf("-rm") > -1;
		var outdir = args.length > 1 && args[1] != "-k" && args[1] != "-rm"? Bio.PathAppendSeperator(args[1]): null;
		var encryptionKey = readEncryptionKeyArgument(keyArgPos > 0? args[keyArgPos + 1]: null);
		var key = Bio.HexToBytes(encryptionKey, false);
		var iSkipped = 0, iErrors = 0;
		var promptOptions = Bio.defaultPromptOptions;
		promptOptions.push(new Bio.PromptOption("Rename", "r", ACTION_RENAME));
		promptOptions.push(new Bio.PromptOption("Rename All", "l", ACTION_RENAME, true));
		
		for (i in 0...files.length) {
			try {
				if (FileSystem.isDirectory(files[i])) continue;
			} 
			catch (e:Dynamic) {
				continue;
			}
			
			var fileParts = Bio.FileGetParts(files[i]);
			//trace(fileParts);
			if (!validExtensions.exists(fileParts.extension)){
				Bio.Cout("Invalid extension '" + fileParts.extension + "' for file " + fileParts.name);
				iSkipped++;
				continue;
			}
			
			var outFileName = (outdir == null? fileParts.directory: outdir) + fileParts.name;
			var extension = validExtensions[fileParts.extension];
			var outFile = outFileName + extension;
			if (FileSystem.exists(outFile)) {
				var userChoice:Dynamic = Bio.Prompt("The file " + fileParts.name + extension + " already exists. Overwrite?", "OutOverwrite", promptOptions);
				
				if (userChoice == false) {
					Bio.Cout("Skipped file " + fileParts.fullName);
					iSkipped++;
					continue;
				}
				else if (userChoice == ACTION_RENAME) {
					var i = 2;
					
					while (FileSystem.exists(outFile)) {
						outFile = outFileName + ' ($i)$extension';
						i++;
					}
					
					Bio.Cout("Renamed file to " + outFile, Bio.LogSeverity.DEBUG);
				}
			}
			
			var bytes = File.getBytes(files[i]);
			bytes = bytes.sub(HEADER_LENGTH, bytes.length - HEADER_LENGTH);
			
			for (j in 0...HEADER_LENGTH) {
				bytes.set(j, bytes.get(j) ^ key.get(j));
			}
			
			try {
				File.saveBytes(outFile, bytes);
			}
			catch (exception:Dynamic) {
				Bio.Error("Failed to write file " + outFile + ", error: " + exception);
				iErrors++;
				continue;
			}
			Bio.Cout('${i + 1}/${files.length}\t${fileParts.name}');
			if (deleteOriginalFiles) {
				try {
					FileSystem.deleteFile(files[i]);
				}
				catch (exception:Dynamic) {
					Bio.Error("Failed to delete file " + files[i] + ", error: " + exception);
				}
			}
		}
		
		if (iErrors > 0) Bio.Warning('$iErrors files failed to decrypt');
		if (iSkipped > 0) Bio.Warning('$iSkipped files were skipped');
		Bio.Cout("All OK");
	}
	
	private static function readInputFileArgument(file:String){
		if (!FileSystem.exists(file)) {
			Bio.Error("The input file " + file + " does not exist.", 1);
			return null;
		}
		else if (FileSystem.isDirectory(file)) {
			return FileSystem.readDirectory(file).map(function(s:String) {
				return Bio.PathAppendSeperator(file) + s;
			});
		}
		else {
			return [file];
		}
	}
	
	private static function readEncryptionKeyArgument(?rawString:String) {
		var encryptionKey = rawString;
		if (rawString == null) {
			var f = Bio.FileGetParts(files[0]).directory;
			for (i in 0...5) {
				var tempPath = f + "data/System.json";
				if (FileSystem.exists(tempPath)) {
					rawString = tempPath;
					break;
				}
				f += "../";
			}
		}
		
		if (rawString != null && FileSystem.exists(rawString)) {
			Bio.Cout("Trying to find encryption key at path " + rawString);
			try {
				var content = File.getContent(rawString);
				var json = Json.parse(content);
				encryptionKey = json.encryptionKey;
			} 
			catch (e:Dynamic) {
				Bio.Error("Failed to read encryption key from file " + rawString, 2);
			}
		}
		else {
			rawString = Bio.StringPrompt("Failed to automatically determine encrytion key. Please enter the path to System.json (default: <gamedir>\\www\\data\\System.json) or the encryption key (found in said file):");
			if (rawString == "") Sys.exit(2);
			return readEncryptionKeyArgument(rawString);
		}
		return encryptionKey;
	}
}