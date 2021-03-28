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
import std.algorithm;
import std.array;
import omc.parse.lexer;
import omc.parse.parser;

void main(string[] args) {
    OmAstModule[] astModules;
	foreach(file; args[1..$]) {
        auto lexer = OmLexer(file, readText(file));
        auto parser = OmParser(lexer);
        astModules ~= parser.parseModule();
        if (lexer.errorCount + parser.errorCount > 0) writefln("%-(%s\n%)", lexer.messages ~ parser.messages);
    }
}