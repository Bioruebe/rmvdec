using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using BioLib;
using BioLib.Streams;
using Newtonsoft.Json.Linq;

namespace rmvdec {
	class Options {
		public string inputPath;
		public string outputDirectory;
		public string encryptionKey;
		public bool removeEncryptedFiles = false;
		public bool skipExtensionCheck = false;
		public bool includeSubdirectories = false;
	}

	class Program {
		private static Options options = new Options();

		private const int HEADER_LENGTH = 16;
		private const string PROMPT_ID = "rmvdec_overwrite";
		private const string SYSTEM_JSON_PATH = @"data\System.json";

		private static readonly Dictionary<string, string> validExtensions = new Dictionary<string, string>() {
			{ ".rpgmvp", ".png" },
			{ ".png_", ".png" },
			{ ".rpgmvm", ".m4a" },
			{ ".rpgmvo", ".ogg" }
		};

		static void Main(string[] args) {
			Bio.Header("rmvdec", "2.2.0", "2018-2023", "A decrypter for RPG-Maker-MV resource files (.rpgmvp, .rpgmvo, rpgmvm)", "<input_file>|<input_dir> [<output_dir>] [-r] [-rm] [-f] [-k <decryption_key>|<path_to_System.json>]");
			if (Bio.HasCommandlineSwitchHelp(args)) return;

			ParseCommandLine(args);
			FindEncryptionKey();

			Bio.Debug("Decryption key: " + options.encryptionKey);
			if (string.IsNullOrEmpty(options.encryptionKey)) Bio.Error("Failed to find decryption key or invalid key specified. Make sure the folder structure is correct (the game must be playable) or provide the key using the -k command line parameter.", Bio.EXITCODE.MISSING_FILE);

			var key = Bio.HexToBytes(options.encryptionKey);

			Bio.Cout();
			var files = GetFiles(options.inputPath);
			var skipped = 0;
			for (var i = 0; i < files.Length; i++) {
				Bio.Progress(Path.GetFileName(files[i]), i + 1, files.Length);
				if (!Extract(files[i], key)) skipped++;
			}

			Bio.Cout();

			if (skipped > 0) {
				Bio.Warn($"{skipped} files were skipped");
			}
			else {
				Bio.Cout("All OK");
			}

			Bio.Pause();
		}

		static string[] GetFiles(string path) {
			if (!Bio.IsDirectory(path)) return new string[] { path };

			return Directory.GetFiles(path, "*", options.includeSubdirectories? SearchOption.AllDirectories: SearchOption.TopDirectoryOnly);
		}

		static bool Extract(string path, byte[] key) {
			if (!File.Exists(path)) Bio.Error($"The file {path} does not exist.", Bio.EXITCODE.IO_ERROR);

			var name = Path.GetFileNameWithoutExtension(path);
			var extension = Path.GetExtension(path);
			if (validExtensions.ContainsKey(extension)) {
				extension = validExtensions[extension];
			}
			else if (options.skipExtensionCheck) {
				extension = extension.EndsWith("_")? extension.TrimEnd('_'): extension + ".decrypted";
			}
			else {
				Bio.Warn($"Invalid extension {extension} for file {name}");
				return false;
			}

			try {
				var relativePath = Bio.PathRemoveLeadingSeparator(Bio.PathGetDirectory(path).Replace(options.inputPath, ""));
				var outputPath = Bio.GetSafeOutputPath(Path.Combine(options.outputDirectory, relativePath), name + extension);
				outputPath = Bio.EnsureFileDoesNotExist(outputPath, PROMPT_ID);
				if (outputPath == null) return false;

				using (var inputStream = File.OpenRead(path)) {
					using (var outputStream = Bio.FileCreate(outputPath)) {
						outputStream.Write(DecryptHeader(inputStream, key), 0, HEADER_LENGTH);
						inputStream.CopyTo(outputStream);
					}
				}

				if (options.removeEncryptedFiles) Bio.FileDelete(path);
			}
			catch (Exception e) {
				Bio.Error("Failed to extract file: " + e);
				return false;
			}

			return true;
		}

		static byte[] DecryptHeader(Stream inputStream, byte[] key) {
			inputStream.Skip(HEADER_LENGTH);
			var header = new byte[HEADER_LENGTH];
			inputStream.Read(header, 0, HEADER_LENGTH);

			for (var i = 0; i < HEADER_LENGTH; i++) {
				header[i] = (byte)(header[i] ^ key[i]);
			}

			return header;
		}

		static void FindEncryptionKey() {
			if (string.IsNullOrEmpty(options.encryptionKey))
				options.encryptionKey = Bio.FileFindBySubDirectory(options.inputPath, SYSTEM_JSON_PATH, 5);

			if (File.Exists(options.encryptionKey)) ReadEncryptionKey();
		}

		static void ReadEncryptionKey() {
			try {
				var fileContent = File.ReadAllText(options.encryptionKey);
				var json = JObject.Parse(fileContent);
				options.encryptionKey = json["encryptionKey"].Value<string>();
			}
			catch (Exception e) {
				Bio.Error($"Failed to automatically determine encryption key: {e}.\nPlease use the -k parameter to specify either the path to System.json (default: <gamedir>\\www\\data\\System.json) or the encryption key (found in said file).", Bio.EXITCODE.RUNTIME_ERROR);
			}
		}

		static void ParseCommandLine(string[] args) {
			if (args.Length < 1) Bio.Error("No input file specified.", Bio.EXITCODE.INVALID_INPUT);
			options.inputPath = args[0];

			if (!Bio.PathExists(options.inputPath)) Bio.Error($"The specified file {options.inputPath} does not exist.", Bio.EXITCODE.INVALID_INPUT);

			if (args.Contains("-rm") || args.Contains("--remove")) options.removeEncryptedFiles = true;
			if (args.Contains("-f") || args.Contains("--force")) options.skipExtensionCheck = true;
			if (args.Contains("-r") || args.Contains("--recurse") || args.Contains("--recursive")) options.includeSubdirectories = true;

			var keyArgPosition = Array.FindIndex(args, (arg) => arg == "-k");
			if (keyArgPosition > -1) {
				if (args.Length < keyArgPosition + 1) {
					Bio.Error("Please specify the key when using the -k parameter", Bio.EXITCODE.INVALID_PARAMETER);
				}
				else {
					options.encryptionKey = args[keyArgPosition + 1];
				}
			}

			if (args.Length > 1 && !args[1].StartsWith("-")) options.outputDirectory = args[1];

			if (options.outputDirectory == null) options.outputDirectory = Bio.PathGetDirectory(options.inputPath);
			options.outputDirectory = Bio.PathAppendSeparator(options.outputDirectory);
		}
	}
}
