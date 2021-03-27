/* 
 * omc: The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.context;

import std.format: format;
import omc.parse.token;
import omc.parse.ast;
import omc.semantic.symbol;

struct OmContext {
	string[] messages;
	size_t warnCount, errorCount;
	OmAstModule[] astModules;
	OmModuleSymbol moduleSymbols;

	void error(Args...)(OmSrcLocation location, string fmt, Args args) {
		this.errorCount += 1;
		messages ~= format("Error: %s in %s", format(fmt, args), location);
	}

	void warn(Args...)(OmSrcLocation location, string fmt, Args args) {
		this.warnCount += 1;
		messages ~= format("Warning: %s in %s", format(fmt, args), location);
	}

	void info(Args...)(OmSrcLocation location, string fmt, Args args) {
		messages ~= format("Info: %s in %s", format(fmt, args), location);
	}
}