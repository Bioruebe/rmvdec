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
	private static var files:Array<String>;
	private static var validExtensions = ["rpgmvp" => ".png", "rpgmvm" => ".m4a", "rpgmvo" => ".ogg"];
	
	static function main() {
		Bio.Header("rmvdec", "1.0.1", "A simple decrypter for RPG-Maker-MV ressource files (.rpgmvp, .rpgmvo, rpgmvm)", "<input_file>|<input_dir> [<output_dir>] [-k <decrytion_key>|<path_to_System.json>]");
		Bio.Seperator();
		
		var args = Sys.args();
		if (args.length < 1) Bio.Error("Please specify an input path. This can either be a file or a directory containing RPG-Maker-MV ressource files.", 1);
		
		files = readInputFileArgument(args[0]);
		var keyArgPos = args.indexOf("-k");
		var outdir = args.length > 1 && args[1] != "-k"? Bio.PathAppendSeperator(args[1]): null;
		var encryptionKey = readEncryptionKeyArgument(keyArgPos > 0? args[keyArgPos + 1]: null);
		var key = Bio.HexToBytes(encryptionKey, false);
		var iSkipped = 0;
		
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
			
			var outFile = (outdir == null? fileParts.directory: outdir) + fileParts.name + validExtensions[fileParts.extension];
			if (FileSystem.exists(outFile) && !Bio.Prompt("The file " + fileParts.name + validExtensions[fileParts.extension] + " already exists. Overwrite?", "OutOverwrite")) {
				Bio.Cout("Skipped file " + fileParts.fullName);
				iSkipped++;
				continue;
			}
			
			var bytes = File.getBytes(files[i]);
			bytes = bytes.sub(HEADER_LENGTH, bytes.length - HEADER_LENGTH);
			
			for (j in 0...HEADER_LENGTH) {
				bytes.set(j, bytes.get(j) ^ key.get(j));
			}
			
			File.saveBytes(outFile, bytes);
			Bio.Cout('${i + 1}/${files.length}\t${fileParts.name}');
		}
		
		if (iSkipped < 0) Bio.Warning('$iSkipped files were skipped');
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
			Bio.Error("Failed to automatically determine encrytion key. Please specify the path to System.json or the encryption key as a second command line parameter.", 2);
		}
		return encryptionKey;
	}
}