#!/usr/bin/env dub
/+
dub.json:
{
	"name": "list",
	"description": "Lists contents of archive using libarchive",
	"dependencies": {
		"derelict-libarchive": {
			"path": "./../"
		},
		"derelict-util": "~>3.0.0-beta.1"
	}
}
+/
/**
 * Lists contents of file.
 * See Also: https://github.com/libarchive/libarchive/wiki/Examples#List_contents_of_Archive_stored_in_File
 */

import derelict.libarchive;
import std.stdio : File, stdin, stderr, writeln, writefln;
import std.string : fromStringz;

/**
 * This is a simple example, which should work fine on every system.
 * This callback tells DerelictLibArchive loader not to throw if it cannot load symbols we don't need.
 */
import derelict.util.exception : ShouldThrow;
ShouldThrow missingSymCB(string symbol) {
	import std.algorithm : canFind;
	return [
		"archive_read_new",
		"archive_read_free",
		"archive_read_support_filter_all",
		"archive_read_support_format_all",
		"archive_read_open_FILE",
		"archive_error_string",
		"archive_read_next_header",
		"archive_entry_pathname"
	].canFind(symbol) ? ShouldThrow.Yes : ShouldThrow.No;
}

shared static this() { // This code runs before main()
	DerelictLibArchive.missingSymbolCallback = &missingSymCB;
	DerelictLibArchive.load(); // Loads libarchive
}

int main(string[] args) {
	if(args.length < 2) { // args[0] is always a program name
		writeln("Usage:");
		writeln("\tlist input \tFrom file");
		writeln("\tlist -     \tFrom STDIN");
		return 0;
	}

	File input;
	if(args[1] == "-") {
		input = stdin; // If "-" given, read from STDIN
	} else {
		input = File(args[1], "rb"); // Else, open file (Fails if file doesn't exist)
	}

	archive* ar = archive_read_new();
	scope(exit) archive_read_free(ar); // `ar` will be freed when the scope exits

	archive_read_support_filter_all(ar);
	archive_read_support_format_all(ar);

	auto r = archive_read_open_FILE(ar, input.getFP); // `.getFP` returns C FILE handle
	if(r < ARCHIVE_OK) {
		stderr.writefln("Libarchive error: %s", archive_error_string(ar).fromStringz);
		return r;
	}

	archive_entry* entry;
	while(archive_read_next_header(ar, &entry) == ARCHIVE_OK)
		writeln(archive_entry_pathname(entry).fromStringz);

	return 0;
}
