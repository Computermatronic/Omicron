/* 
 * omc: the official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.semantic.symbol;

import omc.parse.token;
import omc.parse.ast;
import omc.semantic.scope_;

interface OmSymbol {
	@property string name();
	@property OmSrcLocation location();

	@property OmScope parentScope();
	@property OmModuleSymbol parentModule();
}

mixin template OmSymbolImpl(OmAstDeclarationType: OmAstDeclaration) {
	OmAstDeclarationType astNode;
	OmScope parent;

	@property string name() { return astNode.name; }
	@property OmSrcLocation location() { return astNode.location; }

	@property OmScope parentScope() { return parent; }
	@property OmModuleSymbol parentModule() { 
		if (auto moduleSymbol = cast(OmModuleSymbol)parentScope) return moduleSymbol;
		else if (parentScope !is null) return parentScope.parentModule;
		else return null;
	}
}

class OmModuleSymbol: OmSymbol, OmScope {
	mixin OmSymbolImpl!OmAstModule;
	mixin OmScopeImpl;

	OmSymbol[] findSymbol(string name) {
		OmSymbol[] result;
		if (auto existingSymbol = name in symbolTable) result ~= *existingSymbol;
		result ~= getImportedSymbol(name);
		return result;
	}
}

class OmEnumSymbol: OmSymbol, OmScope {
	mixin OmSymbolImpl!OmAstEnum;
	mixin OmScopeImpl;
}

class OmStructSymbol: OmSymbol, OmScope {
	mixin OmSymbolImpl!OmAstStruct;
	mixin OmScopeImpl;
}

class OmClassSymbol: OmSymbol, OmScope {
	mixin OmSymbolImpl!OmAstClass;
	mixin OmScopeImpl;
}

class OmInterfaceSymbol: OmSymbol, OmScope {
	mixin OmSymbolImpl!OmAstInterface;
	mixin OmScopeImpl;
}

class OmFunctionSymbol: OmSymbol, OmScope {
	mixin OmSymbolImpl!OmAstFunction;
	mixin OmScopeImpl;
}

class OmEnumMemberSymbol: OmSymbol {
	mixin OmSymbolImpl!OmAstEnumMember;
}

class OmAliasSymbol: OmSymbol {
	mixin OmSymbolImpl!OmAstAlias;
}

class OmDefSymbol: OmSymbol {
	mixin OmSymbolImpl!OmAstDef;
}