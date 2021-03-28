/* 
 * omc: the official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.semantic.scope_;

import omc.parse.token;
import omc.semantic.symbol;

interface OmScope {
	OmSrcLocation location();
	OmModuleSymbol parentModule();
	OmScope parentScope();

	void addImport(OmModuleSymbol moduleSymbol, string[] whitelist, bool isPublic);

	void insertSymbol(OmSymbol symbol);
	OmSymbol[] getSymbol(string name);
	OmSymbol[] findSymbol(string name);
}

mixin template OmScopeImpl() {
	struct Import {
		OmModuleSymbol symbol;
		string[] whitelist;
		bool isPublic;
	}

	OmSymbol[][string] symbolTable;
	Import[] importTable;

	void addImport(OmModuleSymbol symbol, string[] whitelist, bool isPublic) {
		importTable ~= Import(symbol, whitelist, isPublic);
	}

	void insertSymbol(OmSymbol symbol) {
		auto existingSymbol = symbol.name in symbolTable;
		if (existingSymbol !is null) (*existingSymbol) ~= symbol;
		else symbolTable[symbol.name] = [symbol];
	}

	OmSymbol[] getSymbol(string name) {
		OmSymbol[] result;
		if (auto existingSymbol = name in symbolTable) result ~= *existingSymbol;
		result ~= getImportedSymbol(name, true);
		return result;
	}

	OmSymbol[] findSymbol(string name) {
		OmSymbol[] result;
		if (auto existingSymbol = name in symbolTable) result ~= *existingSymbol;
		result ~= getImportedSymbol(name);
		if (parentScope !is null) result ~= parentScope.findSymbol(name);
		return result;
	}
	
	OmSymbol[] getImportedSymbol(string name, bool publicOnly = false) {
		import std.algorithm: canFind;
		OmSymbol[] result;
		foreach(import_; importTable) {
			if (publicOnly && !import_.isPublic) continue;
			if (import_.whitelist is null || import_.whitelist.canFind(name)) result ~= import_.symbol.getSymbol(name);
		}
		return result;
	}
}

class OmStatementScope: OmScope {
	import omc.parse.ast: OmAstStatement;
	mixin OmScopeImpl;
	OmAstStatement astNode;
	OmScope parent;

	@property OmSrcLocation location() { return astNode.location; }
	@property OmScope parentScope() { return parent; }
	@property OmModuleSymbol parentModule() { 
		if (auto moduleSymbol = cast(OmModuleSymbol)parentScope) return moduleSymbol;
		else if (parentScope !is null) return parentScope.parentModule;
		else return null;
	}
}