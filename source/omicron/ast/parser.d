/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module omicron.ast.parser;

import std.format : format;
import omicron.ast.core;
import omicron.ast.token;

//Main parsing function.
ASTModule parseTokens(Token[] tokens) {
	auto state = new ParserState(tokens);
	return state.parseModule();
}

//Category based parsing functions.
ASTStatement parseStatement(ParserState state) {
	nextStatement: switch(state.front.type) with(TokenType) {
		case kw_enum, kw_alias, kw_def, kw_function, kw_template, kw_struct, kw_class, 
			kw_interface, kw_if, kw_foreach, kw_import: return state.parseStatic();
		case kw_for: return state.parseFor();
		case kw_while: return state.parseWhile();
		case kw_switch: return state.parseSwitch();
		case kw_case: return state.parseCase();
		case kw_do: return state.parseDoWhile();
		case kw_with: return state.parseWith();
		case kw_return: return state.parseReturn();
		case kw_break: return state.parseBreak();
		case kw_continue: return state.parseContinue();
		case tk_at: state.parseAttributes(); goto nextStatement;
		default: return state.parseExpressionStatement();
	}
}

ASTStatic parseStatic(ParserState state) {
	nextStatic: switch(state.front.type) with(TokenType) {
		case kw_enum, kw_alias, kw_def, kw_function, kw_template, kw_struct, kw_class, 
			kw_interface, kw_import: return state.parseDeclaration();
		case kw_if: return state.parseIf();
		case kw_foreach: return state.parseForeach();
		case tk_at: state.parseAttributes(); goto nextStatic;
		default: throw new ParserException(format("Unrecognized declaration %s", state.front.text), state.front.location);
	}
}

ASTDeclaration parseDeclaration(ParserState state) {
	nextDeclaration: switch(state.front.type) with(TokenType) {
		case kw_enum: return state.parseEnum();
		case kw_alias: return state.parseAlias();
		case kw_def: return state.parseDef();
		case kw_function: return state.parseFunction();
		case kw_template: return state.parseTemplate();
		case kw_struct: return state.parseStruct();
		case kw_class: return state.parseClass();
		case kw_interface: return state.parseInterface();
		case kw_import: return state.parseImport();
		case tk_at: state.parseAttributes(); goto nextDeclaration;
		default: throw new ParserException(format("Unrecognized declaration %s", state.front.text), state.front.location);
	}
}

ASTExpression parseExpression(ParserState state, int precedence = int.max) {
	ASTExpression expression;

	switch(state.front.type) with(TokenType) {
		case ud_identifier:
			auto node = state.makeNode!ASTIdentifier();
			node.name = state.expectToken(TokenType.ud_identifier).text;
			expression = node;
			break;

		case tk_leftParen:
			auto node = state.makeNode!ASTTuple(TokenType.tk_leftParen);
			node.members = state.parseList!parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			expression = node;
			break;

		case kw_typeof:
			auto node = state.makeNode!ASTTypeOf(TokenType.kw_typeof);
			state.expectToken(TokenType.tk_leftParen);
			node.subject = state.parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			expression = node;
			break;

		case tk_asterick, tk_ampersand:
			auto node = state.makeNode!ASTUnaryOperator();
			node.operator = cast(ASTUnaryOperator.Operator)state.popFront().type;
			node.subject = state.parseExpression(Precedence.unaryPointerOperator);
			expression = node;
			break;

		case tk_plus, tk_minus:
			auto node = state.makeNode!ASTUnaryOperator();
			node.operator = cast(ASTUnaryOperator.Operator)state.popFront().type;
			node.subject = state.parseExpression(Precedence.unaryNegationOperator);
			expression = node;
			break;

		case tk_increment, tk_decrement:
			auto node = state.makeNode!ASTUnaryOperator();
			node.operator = cast(ASTUnaryOperator.Operator)state.popFront().type;
			node.subject = state.parseExpression(Precedence.unaryIncrementOperator);
			expression = node;
			break;

		case kw_if:
			auto node = state.makeNode!ASTTinaryOperator(TokenType.tk_question);
			state.expectToken(TokenType.tk_leftParen);
			node.subject = state.parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			node.lhs = state.parseExpression();
			state.expectToken(TokenType.kw_else);
			node.rhs = state.parseExpression();
			break;

		case kw_cast:
			auto node = state.makeNode!ASTCast(TokenType.kw_cast);
			state.expectToken(TokenType.tk_colon);
			node.type = state.parseReference();
			state.expectToken(TokenType.tk_leftParen);
			node.subject = state.parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			expression = node;
			break;

		case kw_new:
			auto node = state.makeNode!ASTNew(TokenType.kw_new);
			state.expectToken(TokenType.tk_colon);
			node.type = state.parseReference();
			state.expectToken(TokenType.tk_leftParen);
			if (!state.testForToken(TokenType.tk_rightParen)) node.arguments = state.parseList!parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			expression = node;
			break;

		case tk_leftBracket:
			auto node = state.makeNode!ASTArray(TokenType.tk_leftBracket);
			if (!state.testForToken(TokenType.tk_rightParen)) node.members = state.parseList!parseExpression();
			state.expectToken(TokenType.tk_rightBrace);
			expression = node;
			break;

		case ud_string:
			auto node = state.makeNode!ASTString();
			node.literal = state.expectToken(TokenType.ud_string).text;
			expression = node;
			break;

		case ud_char:
			auto node = state.makeNode!ASTChar();
			node.literal = state.expectToken(TokenType.ud_char).text;
			expression = node;
			break;

		case ud_integer:
			auto node = state.makeNode!ASTInteger();
			node.literal = state.expectToken(TokenType.ud_integer).text;
			expression = node;
			break;

		case ud_float:
			auto node = state.makeNode!ASTFloat();
			node.literal = state.expectToken(TokenType.ud_float).text;
			expression = node;
			break;

		default: throw new ParserException(format("Unrecognized expression %s", state.front.text), state.front.location);
	}

	nextExpression: switch(state.front.type) with(TokenType) {
		case TokenType.tk_dot:
			if (Precedence.dispatch > precedence) break;
			auto node = state.makeNode!ASTDispatch(TokenType.tk_dot);
			node.subject = expression;
			node.name = state.expectToken(TokenType.ud_identifier).text;
			expression = node;
			goto nextExpression;

		case tk_leftBracket:
			if (Precedence.subscript > precedence) break;
			auto node = state.makeNode!ASTSubscript(TokenType.tk_leftBracket);
			node.subject = expression;
			if (!state.testForToken(TokenType.tk_rightBracket)) node.arguments = state.parseList!parseExpression();
			state.expectToken(TokenType.tk_rightBracket);
			expression = node;
			goto nextExpression;

		case tk_colon:
			if (Precedence.templateInstance > precedence) break;
			auto node = state.makeNode!ASTTemplateInstance(TokenType.tk_colon);
			node.subject = expression;
			if (state.advanceForToken(TokenType.tk_leftParen)) {
				if (!state.testForToken(TokenType.tk_rightParen)) node.arguments = state.parseList!parseExpression();
				state.expectToken(TokenType.tk_rightParen);
			} else {
				node.arguments ~= state.parseExpression();
			}
			expression = node;
			goto nextExpression;

		case tk_asterick:
			auto next = state.frontN(2)[$-1].type;
			if (ud_identifier != next && ud_string != next    && ud_char != next      && ud_integer != next   && 
			ud_float != next          && tk_leftParen != next && tk_increment != next && tk_decrement != next &&
			tk_plus != next           && tk_minus != next     && tk_ampersand != next && tk_asterick != next  && 
			tk_not != next            && tk_tilde != next     && kw_new != next       && cast(ASTReference)expression !is null) {
				auto node = state.makeNode!ASTPointerType(TokenType.tk_asterick);
				node.subject = cast(ASTReference)expression;
				expression = node;
				goto nextExpression;
			} else goto case;

		case tk_slash, tk_percent, tk_power:
			if (Precedence.multiplacativeOperator > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.multiplacativeOperator);
			expression = node;
			goto nextExpression;

		case tk_plus, tk_minus:
			if (Precedence.additiveOperator > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.additiveOperator);
			expression = node;
			goto nextExpression;

		case tk_greaterThan, tk_lessThan, tk_greaterThanEqual, tk_lessThanEqual:
			if (Precedence.comparativeOperator > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.comparativeOperator);
			expression = node;
			goto nextExpression;

		case tk_equal, tk_notEqual:
			if (Precedence.equityOperator > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.equityOperator);
			expression = node;
			goto nextExpression;

		case tk_shiftLeft, tk_shiftRight:
			if (Precedence.bitShiftOperator > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.bitShiftOperator);
			expression = node;
			goto nextExpression;

		case tk_ampersand:
			if (Precedence.bitAnd > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.bitAnd);
			expression = node;
			goto nextExpression;

		case tk_poll:
			if (Precedence.bitOr > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.bitOr);
			expression = node;
			goto nextExpression;

		case tk_hash:
			if (Precedence.bitXor > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.bitXor);
			expression = node;
			goto nextExpression;

		case tk_logicalAnd:
			if (Precedence.and > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.and);
			expression = node;
			goto nextExpression;

		case tk_logicalOr:
			if (Precedence.or > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.or);
			expression = node;
			goto nextExpression;

		case tk_logicalXor:
			if (Precedence.xor > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.xor);
			expression = node;
			goto nextExpression;

		case tk_tilde, tk_slice:
			if (Precedence.concat > precedence) break;
			auto node = state.makeNode!ASTBinaryOperator();
			node.lhs = expression;
			node.operator = cast(ASTBinaryOperator.Operator)state.popFront().type;
			node.rhs = state.parseExpression(Precedence.concat);
			expression = node;
			goto nextExpression;

		case tk_increment, tk_decrement:
		if (Precedence.unaryPostIncrementOperator > precedence) break;
			auto node = state.makeNode!ASTUnaryOperator();
			node.operator = state.popFront().type == tk_increment ? ASTUnaryOperator.Operator.postIncrement : 
				ASTUnaryOperator.Operator.postDecrement;
			node.subject = expression;
			expression = node;
			break;

		case tk_assign, tk_assignAdd, tk_assignSubtract, tk_assignMultiply, tk_assignDivide, tk_assignModulo, tk_assignPower,
		tk_assignConcat, tk_assignAnd, tk_assignOr, tk_assignXor:
			if (Precedence.assignmentOperator > precedence) break;
			auto node = state.makeNode!ASTAssignmentOperator();
			node.subject = expression;
			node.operator = cast(ASTAssignmentOperator.Operator)state.popFront().type;
			node.assignment = state.parseExpression(Precedence.assignmentOperator);
			expression = node;
			goto nextExpression;

		case tk_leftParen:
			if (Precedence.call > precedence) break;
			auto node = state.makeNode!ASTCall(TokenType.tk_leftParen);
			node.subject = expression;
			if (!state.testForToken(TokenType.tk_rightParen)) node.arguments = state.parseList!parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			expression = node;
			goto nextExpression;

		case tk_apply:
			if (Precedence.apply > precedence) break;
			auto node = state.makeNode!ASTApply(TokenType.tk_apply);
			node.subject = expression;
			node.name = state.expectToken(TokenType.ud_identifier).text;
			goto nextExpression;

		case kw_is:
			if (Precedence.is_ > precedence) break;
			auto node = state.makeNode!ASTIs(TokenType.kw_is);
			node.lhs = expression;
			node.rhs = state.parseExpression(Precedence.is_);
			goto nextExpression;

		default: break;
	}
	return expression;
}

ASTReference parseReference(ParserState state, int precedence = int.max) {
	ASTReference reference;

	switch(state.front.type) with(TokenType) {
		case ud_identifier:
			auto node = state.makeNode!ASTIdentifier();
			node.name = state.expectToken(TokenType.ud_identifier).text;
			reference = node;
			break;

		case tk_leftParen:
			auto node = state.makeNode!ASTTuple(TokenType.tk_leftParen);
			node.members = cast(ASTExpression[])state.parseList!parseReference();
			state.expectToken(TokenType.tk_rightParen);
			reference = node;
			break;

		case kw_typeof:
			auto node = state.makeNode!ASTTypeOf(TokenType.kw_typeof);
			state.expectToken(TokenType.tk_leftParen);
			node.subject = state.parseExpression();
			state.expectToken(TokenType.tk_rightParen);
			reference = node;
			break;
		default: throw new ParserException(format("Unrecognized expression %s", state.front.text), state.front.location);
	}

	nextReference: switch(state.front.type) with(TokenType) {
		case TokenType.tk_dot:
			if (Precedence.dispatch > precedence) break;
			auto node = state.makeNode!ASTDispatch(TokenType.tk_dot);
			node.subject = reference;
			node.name = state.expectToken(TokenType.ud_identifier).text;
			reference = node;
			goto nextReference;

		case tk_leftBracket:
			if (Precedence.subscript > precedence) break;
			auto node = state.makeNode!ASTSubscript(TokenType.tk_leftBracket);
			node.subject = reference;
			if (!state.testForToken(TokenType.tk_rightBracket)) node.arguments = cast(ASTExpression[])state.parseList!parseReference();
			state.expectToken(TokenType.tk_rightBracket);
			reference = node;
			goto nextReference;

		case tk_colon:
			if (Precedence.templateInstance > precedence) break;
			auto node = state.makeNode!ASTTemplateInstance(TokenType.tk_colon);
			node.subject = reference;
			if (state.advanceForToken(TokenType.tk_leftParen)) {
				node.arguments = state.parseList!parseExpression();
				state.expectToken(TokenType.tk_rightParen);
			} else {
				node.arguments ~= state.parseReference();
			}
			reference = node;
			goto nextReference;

		case tk_asterick:
			auto node = state.makeNode!ASTPointerType(TokenType.tk_asterick);
			node.subject = cast(ASTReference)reference;
			reference = node;
			goto nextReference;

		default: break;
	}
	return reference;
}

//Syntactic group based parsing functions.
auto parseList(alias func)(ParserState state) {
	import std.traits: ReturnType;

	ReturnType!(func)[] list;
	do {
		list ~= func(state);
	} while(!state.empty && state.advanceForToken(TokenType.tk_comma));
	return list;
}

auto parseBlock(alias func)(ParserState state) {
	import std.traits: ReturnType;

	ReturnType!(func)[] block;
	if (state.advanceForToken(TokenType.tk_leftBrace)) {
		do {
			block ~= func(state);
		} while(!state.empty && !state.testForToken(TokenType.tk_rightBrace));
		state.expectToken(TokenType.tk_rightBrace);
	} else {
		block ~= func(state);
	}
	return block;
}

auto parseParamaters(alias func)(ParserState state) {
	import std.traits: ReturnType;
	import std.typecons : tuple;

	ReturnType!(func)[] paramaters;
	bool isVaridic;
	state.expectToken(TokenType.tk_leftParen);
	if (!state.advanceForToken(TokenType.tk_rightParen)) {
		paramaters = state.parseList!func();
		if (state.advanceForToken(TokenType.tk_varidic)) isVaridic = true;
		state.expectToken(TokenType.tk_rightParen);
	}
	return tuple(paramaters, isVaridic);
}

//Node component based parsing functions.
ASTDeclaration parseTemplateParamater(ParserState state) {
	switch(state.front.type) with(TokenType) {
		case TokenType.ud_identifier: return state.parseTypeParamater();
		case TokenType.kw_alias: return state.parseAliasParamater();
		case TokenType.kw_def: return state.parseDefParamater();
		default: throw new ParserException(format("Unrecognized declaration %s", state.front.text), state.front.location);
	}
}

//Node based parsing functions.
ASTModule parseModule(ParserState state) {
	auto node = state.makeNode!ASTModule();
	if (state.advanceForToken(TokenType.kw_module)) {
		string[] packageName;
		do {
			packageName ~= state.expectToken(TokenType.ud_identifier).text;
		} while(!state.empty && state.advanceForToken(TokenType.tk_dot));
		node.name = packageName[$-1];
		node.packageName = packageName[0 .. $ - 1];
		state.expectToken(TokenType.tk_semicolon);
	} else {
		import std.path : baseName, stripExtension;
		node.name = state.front.location.file.baseName().stripExtension();
	}
	while(!state.empty) {
		node.members ~= state.parseStatic();
	}
	return node;
}

ASTAlias parseAlias(ParserState state) {
	auto node = state.makeNode!ASTAlias(TokenType.kw_alias);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	state.expectToken(TokenType.tk_assign);
	node.initializer = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTDef parseDef(ParserState state) {
	auto node = state.makeNode!ASTDef(TokenType.kw_def);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_assign)) node.initializer = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTImport parseImport(ParserState state) {
	auto node = state.makeNode!ASTImport(TokenType.kw_import);
	string[] fullName;
	do {
		fullName ~= state.expectToken(TokenType.ud_identifier).text;
	} while(!state.empty && state.advanceForToken(TokenType.tk_dot));
	node.name = fullName[$-1];
	node.packageName = fullName[0..$-1];
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTFunction parseFunction(ParserState state) {
	auto node = state.makeNode!ASTFunction(TokenType.kw_function);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	auto paramaters = state.parseParamaters!parseDefParamater();
	node.paramaters = paramaters[0];
	node.isVaridic = paramaters[1];
	if (state.advanceForToken(TokenType.tk_semicolon)) node.isLinkage = true;
	else node.members = state.parseBlock!parseStatement();
	return node;
}

ASTDefParamater parseDefParamater(ParserState state) {
	auto node = state.makeNode!ASTDefParamater(TokenType.kw_def);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_assign)) node.initializer = state.parseExpression();
	return node;
}

ASTTemplate parseTemplate(ParserState state) {
	auto node = state.makeNode!ASTTemplate(TokenType.kw_template);
	if (!state.testForToken(TokenType.ud_identifier)) node.isAnonymus = true;
	else node.name = state.expectToken(TokenType.ud_identifier).text;
	auto paramaters = state.parseParamaters!parseTemplateParamater();
	node.paramaters = paramaters[0];
	node.isVaridic = paramaters[1];
	if (node.isAnonymus) node.members ~= state.parseStatic();
	else node.members ~= state.parseBlock!parseStatic();
	return node;
}

ASTTypeParamater parseTypeParamater(ParserState state) {
	auto node = state.makeNode!ASTTypeParamater();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	if (state.advanceForToken(TokenType.tk_assign)) node.initializer = state.parseReference();
	return node;
}

ASTAliasParamater parseAliasParamater(ParserState state) {
	auto node = state.makeNode!ASTAliasParamater(TokenType.kw_alias);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_assign)) node.initializer = state.parseExpression();
	return node;
}

ASTEnum parseEnum(ParserState state) {
	auto node = state.makeNode!ASTEnum(TokenType.kw_enum);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	state.expectToken(TokenType.tk_leftBrace);
	node.members = state.parseList!parseEnumMember();
	state.expectToken(TokenType.tk_rightBrace);
	return node;
}

ASTEnumMember parseEnumMember(ParserState state) {
	auto node = state.makeNode!ASTEnumMember();
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_assign)) node.initializer = state.parseExpression();
	return node;
}

ASTStruct parseStruct(ParserState state) {
	auto node = state.makeNode!ASTStruct(TokenType.kw_struct);
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_colon)) node.baseTypes = state.parseList!parseReference();
	if (state.advanceForToken(TokenType.tk_semicolon)) node.isLinkage = true;
	else node.members = state.parseBlock!parseStatic();
	return node;
}

ASTClass parseClass(ParserState state) {
	auto node = state.makeNode!ASTClass(TokenType.kw_class);
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_colon)) node.baseTypes = state.parseList!parseReference();
	else node.members = state.parseBlock!parseStatic();
	return node;
}

ASTInterface parseInterface(ParserState state) {
	auto node = state.makeNode!ASTInterface(TokenType.kw_interface);
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_colon)) node.baseTypes = state.parseList!parseReference();
	else node.members = state.parseBlock!parseStatic();
	return node;
}

ASTIf parseIf(ParserState state) {
	auto node = state.makeNode!ASTIf(TokenType.kw_if);
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!parseStatement();
	if (state.testForToken(TokenType.kw_else)) node.else_ = state.parseElse();
	return node;
}

ASTElse parseElse(ParserState state) {
	auto node = state.makeNode!ASTElse(TokenType.kw_else);
	node.members = state.parseBlock!parseStatement();
	return node;
}

ASTSwitch parseSwitch(ParserState state) {
	auto node = state.makeNode!ASTSwitch(TokenType.kw_switch);
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!parseCase();
	return node;
}

ASTCase parseCase(ParserState state) {
	auto node = state.makeNode!ASTCase(TokenType.kw_case);
	if (state.advanceForToken(TokenType.kw_else)) {
		node.isElseCase = true;
	} else {
		state.expectToken(TokenType.tk_leftParen);
		node.subjects = state.parseList!parseExpression();
		state.expectToken(TokenType.tk_rightParen);
	}
	state.expectToken(TokenType.tk_colon);
	while(!state.testForToken(TokenType.kw_case) && !state.testForToken(TokenType.tk_rightBrace)) {
		node.members ~= state.parseStatement();
	}
	return node;
}

ASTWhile parseWhile(ParserState state) {
	auto node = state.makeNode!ASTWhile(TokenType.kw_while);
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!parseStatement();
	return node;
}

ASTDoWhile parseDoWhile(ParserState state) {
	auto node = state.makeNode!ASTDoWhile(TokenType.kw_do);
	node.members = state.parseBlock!parseStatement();
	state.expectToken(TokenType.kw_while);
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	return node;
}

ASTFor parseFor(ParserState state) {
	auto node = state.makeNode!ASTFor(TokenType.kw_for);
	state.expectToken(TokenType.tk_leftParen);
	if (state.testForToken(TokenType.kw_def)) node.initializer = state.parseDefParamater();
	state.expectToken(TokenType.tk_semicolon);
	if (!state.testForToken(TokenType.tk_semicolon)) node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	if (!state.testForToken(TokenType.tk_leftParen)) node.step = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!parseStatement();
	return node;
}

ASTForeach parseForeach(ParserState state) {
	auto node = state.makeNode!ASTForeach(TokenType.kw_foreach);
	state.expectToken(TokenType.tk_leftParen);
	node.initializers = state.parseList!parseDefParamater();
	state.expectToken(TokenType.tk_semicolon);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!parseStatement();
	return node;
}

ASTWith parseWith(ParserState state) {
	auto node = state.makeNode!ASTWith(TokenType.kw_with);
	if (state.advanceForToken(TokenType.tk_colon)) node.type = state.parseReference();
	state.expectToken(TokenType.tk_leftParen);
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_rightParen);
	node.members = state.parseBlock!parseStatement();
	return node;
}

ASTDelete parseDelete(ParserState state) {
	auto node = state.makeNode!ASTDelete(TokenType.kw_delete);
	if (!state.testForToken(TokenType.tk_semicolon)) node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTReturn parseReturn(ParserState state) {
	auto node = state.makeNode!ASTReturn(TokenType.kw_return);
	if (!state.testForToken(TokenType.tk_semicolon)) node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTBreak parseBreak(ParserState state) {
	auto node = state.makeNode!ASTBreak(TokenType.kw_break);
	//if (!state.testForToken(TokenType.tk_semicolon)) node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTContinue parseContinue(ParserState state) {
	auto node = state.makeNode!ASTContinue(TokenType.kw_continue);
	//if (!state.testForToken(TokenType.tk_semicolon)) node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTExpressionStatement parseExpressionStatement(ParserState state) {
	auto node = state.makeNode!ASTExpressionStatement();
	node.subject = state.parseExpression();
	state.expectToken(TokenType.tk_semicolon);
	return node;
}

ASTAttribute parseAttribute(ParserState state) {
	auto node = state.makeNode!ASTAttribute(TokenType.tk_at);
	node.name = state.expectToken(TokenType.ud_identifier).text;
	if (state.advanceForToken(TokenType.tk_leftParen)) {
		node.arguments = state.parseList!parseExpression();
		state.expectToken(TokenType.tk_rightParen);
	}
	return node;
}

enum Precedence {
	dispatch,
	is_,
	apply,
	templateInstance,
	call,
	subscript,
	unaryPointerOperator,
	unaryNegationOperator,
	unaryIncrementOperator,
	unaryPostIncrementOperator,
	multiplacativeOperator,
	additiveOperator,
	comparativeOperator,
	equityOperator,
	bitShiftOperator,
	bitAnd,
	bitOr,
	bitXor,
	and,
	or,
	xor,
	concat,
	tinary,
	assignmentOperator
}

class ParserState {
	Token[] tokens;
	size_t position;
	ASTAttribute[] attributes;

	this(Token[] tokens) {
		this.tokens = tokens;
	}

	@property bool empty() {
		return position >= tokens.length-1; //EOF
	}

	@property size_t length() {
		return tokens.length - position;
	}

	@property Token front() {
		return tokens[position];
	}

	Token popFront() {
		return tokens[position++];
	}

	Token[] frontN(size_t amount) {
		import std.algorithm : min;
		return tokens[position..min(position+amount, $)];
	}

	Token[] popFrontN(size_t amount) {
		auto result = this.frontN(amount);
		position += result.length;
		return result;
	}

	bool testForToken(TokenType tokenType) {
		return this.front.type == tokenType;
	}

	bool advanceForToken(TokenType tokenType) {
		if (this.front.type == tokenType) {
			this.popFront();
			return true;
		} else {
			return false;
		}
	}

	Token expectToken(TokenType tokenType) {
		if (this.front.type == tokenType) return this.popFront();
		else throw new ParserException(format("Expected %s, got '%s'", tokenDescriptionMap[tokenType], front.text), front.location);
	}

	void parseAttributes() {
		while(this.testForToken(TokenType.tk_at)) {
			this.attributes ~= this.parseAttribute();
		}
	}

	Type makeNode(Type)() {
		auto node = new Type();
		static if(is(Type : ASTStatement)) {
			if (this.testForToken(TokenType.tk_at)) this.parseAttributes();
			node.attributes = this.attributes;
			this.attributes = null;
		}
		node.location = this.front.location;
		return node;
	}

	Type makeNode(Type)(TokenType tokenType) {
		auto result = makeNode!Type();
		this.expectToken(tokenType);
		return result;
	}
}

class ParserException : Exception {
	this(string msg, SourceLocation location, string file = __FILE__, size_t line = __LINE__) {
		super(msg ~ " in " ~ location.toString(), file, line);
	}
}

