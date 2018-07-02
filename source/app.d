/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
import std.stdio;
import std.file : readText;
import omicron.ast;

void main()
{
	auto sourceFile = "test/lexer-test.om";
	auto tokens = lexString(sourceFile, sourceFile.readText);

	auto module_ = parseTokens(tokens);
	auto printer = new ASTPrinter;

	module_.accept(printer);
	writeln(printer.output.data);
}
