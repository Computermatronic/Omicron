/* 
 * omc: the official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.main;

import std.stdio;
import std.file : readText;
import omc.context;
import omc.parse.lexer;
import omc.parse.parser;

int main(string[] args) {
	OmContext context;
	foreach(file; args) context.astModules ~= OmParser(context, OmLexer(context, file, readText(file))).parseModule();
	return 0;
}