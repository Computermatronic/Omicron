/* 
 * omc: The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2020 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.parse.parser;

public import omc.parse.ast;
import std.range;
import omc.context;
import omc.utils;
import omc.parse.lexer;

struct OmParser {
	private {
		OmLexer lexer;
		OmAstAttribute[] attributes;
		OmContext* context;
	}
	
	this(ref OmContext context, OmLexer lexer) { 
		this.context = &context; 
		this.lexer = lexer;
		this.attributes = null;
	}

	//Node based parsing functions.
	OmAstModule parseModule() {
		auto node = this.makeNode!OmAstModule();
		if (this.advanceForToken(OmToken.Type.kw_module)) {
			string[] packageName;
			do {
				packageName ~= this.expectToken(OmToken.Type.ud_identifier).lexeme;
			} while(!lexer.empty && this.advanceForToken(OmToken.Type.tk_dot));
			node.name = packageName[$-1];
			node.packageName = packageName[0 .. $ - 1];
			this.expectToken(OmToken.Type.tk_semicolon);
		} else {
			import std.path : baseName, stripExtension;
			node.name = lexer.front.location.file.baseName().stripExtension();
		}
		while(!lexer.empty) {
			node.members ~= this.parseDeclaration();
		}
		return node;
	}
	
	private {
		OmAstAlias parseAlias() {
			auto node = this.makeNode!OmAstAlias(OmToken.Type.kw_alias);
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			this.expectToken(OmToken.Type.tk_assign);
			node.initializer = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstDef parseDef() {
			auto node = this.makeNode!OmAstDef(OmToken.Type.kw_def);
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_assign)) node.initializer = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstImport parseImport() {
			auto node = this.makeNode!OmAstImport(OmToken.Type.kw_import);
			string[] fullName;
			do {
				fullName ~= this.expectToken(OmToken.Type.ud_identifier).lexeme;
			} while(!lexer.empty && this.advanceForToken(OmToken.Type.tk_dot));
			node.name = fullName[$-1];
			node.packageName = fullName[0..$-1];
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstFunction parseFunction() {
			auto node = this.makeNode!OmAstFunction(OmToken.Type.kw_function);
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			auto paramaters = this.parseParamaters!parseDef();
			node.paramaters = paramaters[0];
			node.isVariadic = paramaters[1];
			if (this.advanceForToken(OmToken.Type.tk_semicolon)) node.isLinkage = true;
			else node.members = this.parseBlock!parseStatement();
			return node;
		}

		OmAstTemplate parseTemplate() {
			auto node = this.makeNode!OmAstTemplate(OmToken.Type.kw_template);
			if (!this.testForToken(OmToken.Type.ud_identifier)) node.isAnonymous = true;
			else node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			auto paramaters = this.parseParamaters!parseTemplateParamater();
			node.paramaters = paramaters[0];
			node.isVariadic = paramaters[1];
			if (node.isAnonymous) node.members ~= this.parseDeclaration();
			else node.members ~= this.parseBlock!parseDeclaration();
			return node;
		}

		OmAstTypeParamater parseTypeParamater() {
			auto node = this.makeNode!OmAstTypeParamater();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			if (this.advanceForToken(OmToken.Type.tk_assign)) node.initializer = this.parseReference();
			return node;
		}

		OmAstAliasParamater parseAliasParamater() {
			auto node = this.makeNode!OmAstAliasParamater(OmToken.Type.kw_alias);
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_assign)) node.initializer = this.parseExpression();
			return node;
		}

		OmAstEnum parseEnum() {
			auto node = this.makeNode!OmAstEnum(OmToken.Type.kw_enum);
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			this.expectToken(OmToken.Type.tk_leftBrace);
			node.members = this.parseList!parseEnumMember();
			this.expectToken(OmToken.Type.tk_rightBrace);
			return node;
		}

		OmAstEnumMember parseEnumMember() {
			auto node = this.makeNode!OmAstEnumMember();
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_assign)) node.initializer = this.parseExpression();
			return node;
		}

		OmAstStruct parseStruct() {
			auto node = this.makeNode!OmAstStruct(OmToken.Type.kw_struct);
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.baseTypes = this.parseList!parseReference();
			if (this.advanceForToken(OmToken.Type.tk_semicolon)) node.isLinkage = true;
			else node.members = this.parseBlock!parseDeclaration();
			return node;
		}

		OmAstClass parseClass() {
			auto node = this.makeNode!OmAstClass(OmToken.Type.kw_class);
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.baseTypes = this.parseList!parseReference();
			else node.members = this.parseBlock!parseDeclaration();
			return node;
		}

		OmAstInterface parseInterface() {
			auto node = this.makeNode!OmAstInterface(OmToken.Type.kw_interface);
			node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.baseTypes = this.parseList!parseReference();
			else node.members = this.parseBlock!parseDeclaration();
			return node;
		}

		OmAstIf parseIf() {
			auto node = this.makeNode!OmAstIf(OmToken.Type.kw_if);
			this.expectToken(OmToken.Type.tk_leftParen);
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			node.members = this.parseBlock!parseStatement();
			if (this.advanceForToken(OmToken.Type.kw_else)) node.elseMembers = this.parseBlock!parseStatement();
			return node;
		}

		OmAstSwitch parseSwitch() {
			auto node = this.makeNode!OmAstSwitch(OmToken.Type.kw_switch);
			this.expectToken(OmToken.Type.tk_leftParen);
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			node.members = this.parseBlock!parseCase();
			return node;
		}

		OmAstCase parseCase() {
			auto node = this.makeNode!OmAstCase(OmToken.Type.kw_case);
			if (this.advanceForToken(OmToken.Type.kw_else)) {
				node.isElseCase = true;
			} else {
				this.expectToken(OmToken.Type.tk_leftParen);
				node.subjects = this.parseList!parseExpression();
				this.expectToken(OmToken.Type.tk_rightParen);
			}
			this.expectToken(OmToken.Type.tk_colon);
			while(!this.testForToken(OmToken.Type.kw_case) && !this.testForToken(OmToken.Type.tk_rightBrace)) {
				node.members ~= this.parseStatement();
			}
			return node;
		}

		OmAstWhile parseWhile() {
			auto node = this.makeNode!OmAstWhile(OmToken.Type.kw_while);
			this.expectToken(OmToken.Type.tk_leftParen);
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			node.members = this.parseBlock!parseStatement();
			return node;
		}

		OmAstDoWhile parseDoWhile() {
			auto node = this.makeNode!OmAstDoWhile(OmToken.Type.kw_do);
			node.members = this.parseBlock!parseStatement();
			this.expectToken(OmToken.Type.kw_while);
			this.expectToken(OmToken.Type.tk_leftParen);
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			return node;
		}

		OmAstFor parseFor() {
			auto node = this.makeNode!OmAstFor(OmToken.Type.kw_for);
			this.expectToken(OmToken.Type.tk_leftParen);
			if (this.testForToken(OmToken.Type.kw_def)) node.initializer = this.parseDef();
			this.expectToken(OmToken.Type.tk_semicolon);
			if (!this.testForToken(OmToken.Type.tk_semicolon)) node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			if (!this.testForToken(OmToken.Type.tk_leftParen)) node.step = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			node.members = this.parseBlock!parseStatement();
			return node;
		}

		OmAstForeach parseForeach() {
			auto node = this.makeNode!OmAstForeach(OmToken.Type.kw_foreach);
			this.expectToken(OmToken.Type.tk_leftParen);
			node.initializers = this.parseList!parseDef();
			this.expectToken(OmToken.Type.tk_semicolon);
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			node.members = this.parseBlock!parseStatement();
			return node;
		}

		OmAstWith parseWith() {
			auto node = this.makeNode!OmAstWith(OmToken.Type.kw_with);
			if (this.advanceForToken(OmToken.Type.tk_colon)) node.type = this.parseReference();
			this.expectToken(OmToken.Type.tk_leftParen);
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_rightParen);
			node.members = this.parseBlock!parseStatement();
			return node;
		}

		OmAstDelete parseDelete() {
			auto node = this.makeNode!OmAstDelete(OmToken.Type.kw_delete);
			if (!this.testForToken(OmToken.Type.tk_semicolon)) node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstReturn parseReturn() {
			auto node = this.makeNode!OmAstReturn(OmToken.Type.kw_return);
			if (!this.testForToken(OmToken.Type.tk_semicolon)) node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstBreak parseBreak() {
			auto node = this.makeNode!OmAstBreak(OmToken.Type.kw_break);
			//if (!this.testForToken(OmToken.Type.tk_semicolon)) node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstContinue parseContinue() {
			auto node = this.makeNode!OmAstContinue(OmToken.Type.kw_continue);
			//if (!this.testForToken(OmToken.Type.tk_semicolon)) node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstExpressionStatement parseExpressionStatement() {
			auto node = this.makeNode!OmAstExpressionStatement();
			node.subject = this.parseExpression();
			this.expectToken(OmToken.Type.tk_semicolon);
			return node;
		}

		OmAstAttribute parseAttribute() {
			auto node = this.makeNode!OmAstAttribute();
			node.name = this.expectToken(OmToken.Type.ud_attribute).lexeme;
			if (this.advanceForToken(OmToken.Type.tk_leftParen)) {
				node.arguments = this.parseList!parseExpression();
				this.expectToken(OmToken.Type.tk_rightParen);
			}
			return node;
		}

		//Category based parsing functions.
		OmAstStatement parseStatement() {
			nextStatement: switch(lexer.front.type) with(OmToken.Type) {
				case kw_enum, kw_alias, kw_def, kw_function, kw_template, kw_struct, kw_class, 
					kw_interface, kw_import: return this.parseDeclaration();
				case kw_if: return this.parseIf();
				case kw_switch: return this.parseSwitch();
				case kw_case: return this.parseCase();
				case kw_for: return this.parseFor();
				case kw_foreach: return this.parseForeach();
				case kw_while: return this.parseWhile();
				case kw_do: return this.parseDoWhile();
				case kw_with: return this.parseWith();
				case kw_return: return this.parseReturn();
				case kw_break: return this.parseBreak();
				case kw_continue: return this.parseContinue();
				case ud_attribute: this.parseAttributes(); goto nextStatement;
				default: return this.parseExpressionStatement();
			}
		}

		OmAstDeclaration parseDeclaration() {
			nextDeclaration: switch(lexer.front.type) with(OmToken.Type) {
				case kw_enum: return this.parseEnum();
				case kw_alias: return this.parseAlias();
				case kw_def: return this.parseDef();
				case kw_function: return this.parseFunction();
				case kw_template: return this.parseTemplate();
				case kw_struct: return this.parseStruct();
				case kw_class: return this.parseClass();
				case kw_interface: return this.parseInterface();
				case kw_import: return this.parseImport();
				case ud_attribute: this.parseAttributes(); goto nextDeclaration;
				default: context.error(lexer.front.location, "Unrecognized declaration %s", lexer.front.lexeme); return null;
			}
		}

		OmAstExpression parseExpression(int precedence = int.max) {
			OmAstExpression expression;

			switch(lexer.front.type) with(OmToken.Type) {
				case ud_identifier:
					auto node = this.makeNode!OmAstIdentifier();
					node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
					expression = node;
					break;

				case tk_leftParen:
					auto node = this.makeNode!OmAstTuple(OmToken.Type.tk_leftParen);
					node.members = this.parseList!parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					expression = node;
					break;

				case kw_typeof:
					auto node = this.makeNode!OmAstTypeOf(OmToken.Type.kw_typeof);
					this.expectToken(OmToken.Type.tk_leftParen);
					node.subject = this.parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					expression = node;
					break;

				case tk_asterisk, tk_ampersand:
					auto node = this.makeNode!OmAstUnaryOperator();
					node.operator = cast(OmAstUnaryOperator.Operator)lexer.stealFront().type;
					node.subject = this.parseExpression(Precedence.unaryPointerOperator);
					expression = node;
					break;

				case tk_plus, tk_minus:
					auto node = this.makeNode!OmAstUnaryOperator();
					node.operator = cast(OmAstUnaryOperator.Operator)lexer.stealFront().type;
					node.subject = this.parseExpression(Precedence.unaryNegationOperator);
					expression = node;
					break;

				case tk_increment, tk_decrement:
					auto node = this.makeNode!OmAstUnaryOperator();
					node.operator = cast(OmAstUnaryOperator.Operator)lexer.stealFront().type;
					node.subject = this.parseExpression(Precedence.unaryIncrementOperator);
					expression = node;
					break;

				case kw_if:
					auto node = this.makeNode!OmAstTrinaryOperator(OmToken.Type.tk_question);
					this.expectToken(OmToken.Type.tk_leftParen);
					node.subject = this.parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					node.lhs = this.parseExpression();
					this.expectToken(OmToken.Type.kw_else);
					node.rhs = this.parseExpression();
					break;

				case kw_cast:
					auto node = this.makeNode!OmAstCast(OmToken.Type.kw_cast);
					this.expectToken(OmToken.Type.tk_colon);
					node.type = this.parseReference();
					this.expectToken(OmToken.Type.tk_leftParen);
					node.subject = this.parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					expression = node;
					break;

				case kw_new:
					auto node = this.makeNode!OmAstNew(OmToken.Type.kw_new);
					this.expectToken(OmToken.Type.tk_colon);
					node.type = this.parseReference();
					this.expectToken(OmToken.Type.tk_leftParen);
					if (!this.testForToken(OmToken.Type.tk_rightParen)) node.arguments = this.parseList!parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					expression = node;
					break;

				case tk_leftBracket:
					auto node = this.makeNode!OmAstArray(OmToken.Type.tk_leftBracket);
					if (!this.testForToken(OmToken.Type.tk_rightParen)) node.members = this.parseList!parseExpression();
					this.expectToken(OmToken.Type.tk_rightBrace);
					expression = node;
					break;

				case ud_string:
					auto node = this.makeNode!OmAstString();
					node.literal = this.expectToken(OmToken.Type.ud_string).literal.get!string;
					expression = node;
					break;

				case ud_char:
					auto node = this.makeNode!OmAstChar();
					node.literal = this.expectToken(OmToken.Type.ud_char).literal.get!dchar;
					expression = node;
					break;

				case ud_integer:
					auto node = this.makeNode!OmAstInteger();
					node.literal = this.expectToken(OmToken.Type.ud_integer).literal.get!long;
					expression = node;
					break;

				case ud_float:
					auto node = this.makeNode!OmAstFloat();
					node.literal = this.expectToken(OmToken.Type.ud_float).literal.get!double;
					expression = node;
					break;

				default: context.error(lexer.front.location, "Unrecognized expression %s", lexer.front.lexeme); return null;
			}

			nextExpression: switch(lexer.front.type) with(OmToken.Type) {
				case OmToken.Type.tk_dot:
					if (Precedence.dispatch > precedence) break;
					auto node = this.makeNode!OmAstDispatch(OmToken.Type.tk_dot);
					node.subject = expression;
					node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
					expression = node;
					goto nextExpression;

				case tk_leftBracket:
					if (Precedence.subscript > precedence) break;
					auto node = this.makeNode!OmAstSubscript(OmToken.Type.tk_leftBracket);
					node.subject = expression;
					if (!this.testForToken(OmToken.Type.tk_rightBracket)) node.arguments = this.parseList!parseExpression();
					this.expectToken(OmToken.Type.tk_rightBracket);
					expression = node;
					goto nextExpression;

				case tk_colon:
					if (Precedence.templateInstance > precedence) break;
					auto node = this.makeNode!OmAstTemplateInstance(OmToken.Type.tk_colon);
					node.subject = expression;
					if (this.advanceForToken(OmToken.Type.tk_leftParen)) {
						if (!this.testForToken(OmToken.Type.tk_rightParen)) node.arguments = this.parseList!parseExpression();
						this.expectToken(OmToken.Type.tk_rightParen);
					} else {
						node.arguments ~= this.parseExpression();
					}
					expression = node;
					goto nextExpression;

				case tk_asterisk:
					auto next = lexer.take(2).array[$-1].type;
					if (ud_identifier != next && ud_string != next	&& ud_char != next	  && ud_integer != next   && 
					ud_float != next		  && tk_leftParen != next && tk_increment != next && tk_decrement != next &&
					tk_plus != next		   && tk_minus != next	 && tk_ampersand != next && tk_asterisk != next  && 
					tk_not != next			&& tk_tilde != next	 && kw_new != next	   && cast(OmAstReference)expression !is null) {
						auto node = this.makeNode!OmAstPointerType(OmToken.Type.tk_asterisk);
						node.subject = cast(OmAstReference)expression;
						expression = node;
						goto nextExpression;
					} else goto case;

				case tk_slash, tk_percent, tk_power:
					if (Precedence.multiplacativeOperator > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.multiplacativeOperator);
					expression = node;
					goto nextExpression;

				case tk_plus, tk_minus:
					if (Precedence.additiveOperator > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.additiveOperator);
					expression = node;
					goto nextExpression;

				case tk_greaterThan, tk_lessThan, tk_greaterThanEqual, tk_lessThanEqual:
					if (Precedence.comparativeOperator > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.comparativeOperator);
					expression = node;
					goto nextExpression;

				case tk_equal, tk_notEqual:
					if (Precedence.equityOperator > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.equityOperator);
					expression = node;
					goto nextExpression;

				case tk_shiftLeft, tk_shiftRight:
					if (Precedence.bitShiftOperator > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.bitShiftOperator);
					expression = node;
					goto nextExpression;

				case tk_ampersand:
					if (Precedence.bitAnd > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.bitAnd);
					expression = node;
					goto nextExpression;

				case tk_poll:
					if (Precedence.bitOr > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.bitOr);
					expression = node;
					goto nextExpression;

				case tk_hash:
					if (Precedence.bitXor > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.bitXor);
					expression = node;
					goto nextExpression;

				case tk_logicalAnd:
					if (Precedence.and > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.and);
					expression = node;
					goto nextExpression;

				case tk_logicalOr:
					if (Precedence.or > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.or);
					expression = node;
					goto nextExpression;

				case tk_logicalXor:
					if (Precedence.xor > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.xor);
					expression = node;
					goto nextExpression;

				case tk_tilde, tk_slice:
					if (Precedence.concat > precedence) break;
					auto node = this.makeNode!OmAstBinaryOperator();
					node.lhs = expression;
					node.operator = cast(OmAstBinaryOperator.Operator)lexer.stealFront().type;
					node.rhs = this.parseExpression(Precedence.concat);
					expression = node;
					goto nextExpression;

				case tk_increment, tk_decrement:
				if (Precedence.unaryPostIncrementOperator > precedence) break;
					auto node = this.makeNode!OmAstUnaryOperator();
					node.operator = lexer.stealFront().type == tk_increment ? OmAstUnaryOperator.Operator.postIncrement : 
						OmAstUnaryOperator.Operator.postDecrement;
					node.subject = expression;
					expression = node;
					break;

				case tk_assign, tk_assignAdd, tk_assignSubtract, tk_assignMultiply, tk_assignDivide, tk_assignModulo, tk_assignPower,
				tk_assignConcat, tk_assignAnd, tk_assignOr, tk_assignXor:
					if (Precedence.assignmentOperator > precedence) break;
					auto node = this.makeNode!OmAstAssignmentOperator();
					node.subject = expression;
					node.operator = cast(OmAstAssignmentOperator.Operator)lexer.stealFront().type;
					node.assignment = this.parseExpression(Precedence.assignmentOperator);
					expression = node;
					goto nextExpression;

				case tk_leftParen:
					if (Precedence.call > precedence) break;
					auto node = this.makeNode!OmAstCall(OmToken.Type.tk_leftParen);
					node.subject = expression;
					if (!this.testForToken(OmToken.Type.tk_rightParen)) node.arguments = this.parseList!parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					expression = node;
					goto nextExpression;

				case tk_apply:
					if (Precedence.apply > precedence) break;
					auto node = this.makeNode!OmAstApply(OmToken.Type.tk_apply);
					node.subject = expression;
					node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
					goto nextExpression;

				case kw_is:
					if (Precedence.is_ > precedence) break;
					auto node = this.makeNode!OmAstIs(OmToken.Type.kw_is);
					node.lhs = expression;
					node.rhs = this.parseExpression(Precedence.is_);
					goto nextExpression;

				default: break;
			}
			return expression;
		}

		OmAstReference parseReference(int precedence = int.max) {
			OmAstReference reference;

			switch(lexer.front.type) with(OmToken.Type) {
				case ud_identifier:
					auto node = this.makeNode!OmAstIdentifier();
					node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
					reference = node;
					break;

				case tk_leftParen:
					auto node = this.makeNode!OmAstTuple(OmToken.Type.tk_leftParen);
					node.members = cast(OmAstExpression[])this.parseList!parseReference();
					this.expectToken(OmToken.Type.tk_rightParen);
					reference = node;
					break;

				case kw_typeof:
					auto node = this.makeNode!OmAstTypeOf(OmToken.Type.kw_typeof);
					this.expectToken(OmToken.Type.tk_leftParen);
					node.subject = this.parseExpression();
					this.expectToken(OmToken.Type.tk_rightParen);
					reference = node;
					break;
				default: context.error(lexer.front.location, "Unrecognized expression %s", lexer.front.lexeme); return null;
			}

			nextReference: switch(lexer.front.type) with(OmToken.Type) {
				case OmToken.Type.tk_dot:
					if (Precedence.dispatch > precedence) break;
					auto node = this.makeNode!OmAstDispatch(OmToken.Type.tk_dot);
					node.subject = reference;
					node.name = this.expectToken(OmToken.Type.ud_identifier).lexeme;
					reference = node;
					goto nextReference;

				case tk_leftBracket:
					if (Precedence.subscript > precedence) break;
					auto node = this.makeNode!OmAstSubscript(OmToken.Type.tk_leftBracket);
					node.subject = reference;
					if (!this.testForToken(OmToken.Type.tk_rightBracket)) node.arguments = cast(OmAstExpression[])this.parseList!parseReference();
					this.expectToken(OmToken.Type.tk_rightBracket);
					reference = node;
					goto nextReference;

				case tk_colon:
					if (Precedence.templateInstance > precedence) break;
					auto node = this.makeNode!OmAstTemplateInstance(OmToken.Type.tk_colon);
					node.subject = reference;
					if (this.advanceForToken(OmToken.Type.tk_leftParen)) {
						node.arguments = this.parseList!parseExpression();
						this.expectToken(OmToken.Type.tk_rightParen);
					} else {
						node.arguments ~= this.parseReference();
					}
					reference = node;
					goto nextReference;

				case tk_asterisk:
					auto node = this.makeNode!OmAstPointerType(OmToken.Type.tk_asterisk);
					node.subject = cast(OmAstReference)reference;
					reference = node;
					goto nextReference;

				default: break;
			}
			return reference;
		}

		OmAstDeclaration parseTemplateParamater() {
			switch(lexer.front.type) with(OmToken.Type) {
				case OmToken.Type.ud_identifier: return this.parseTypeParamater();
				case OmToken.Type.kw_alias: return this.parseAliasParamater();
				case OmToken.Type.kw_def: return this.parseDef();
				default: context.error(lexer.front.location, "Unrecognized declaration %s", lexer.front.lexeme); return null;
			}
		}

		//Syntactic group based parsing functions.
		auto parseList(alias func)() {
			import std.traits: ReturnType;

			ReturnType!(func)[] list;
			do {
				list ~= func();
			} while(!lexer.empty && this.advanceForToken(OmToken.Type.tk_comma));
			return list;
		}

		auto parseBlock(alias func)() {
			import std.traits: ReturnType;

			ReturnType!(func)[] block;
			if (this.advanceForToken(OmToken.Type.tk_leftBrace)) {
				do {
					block ~= func();
				} while(!lexer.empty && !this.testForToken(OmToken.Type.tk_rightBrace));
				this.expectToken(OmToken.Type.tk_rightBrace);
			} else {
				block ~= func();
			}
			return block;
		}

		auto parseParamaters(alias func)() {
			import std.traits: ReturnType;
			import std.typecons : tuple;

			ReturnType!(func)[] paramaters;
			bool isVariadic;
			this.expectToken(OmToken.Type.tk_leftParen);
			if (!this.advanceForToken(OmToken.Type.tk_rightParen)) {
				paramaters = this.parseList!func();
				if (this.advanceForToken(OmToken.Type.tk_variadic)) isVariadic = true;
				this.expectToken(OmToken.Type.tk_rightParen);
			}
			return tuple(paramaters, isVariadic);
		}

		void parseAttributes() {
			while(this.testForToken(OmToken.Type.ud_attribute)) {
				this.attributes ~= this.parseAttribute();
			}
		}

		bool testForToken(OmToken.Type tokenType) {
			return lexer.front.type == tokenType;
		}

		bool advanceForToken(OmToken.Type tokenType) {
			if (lexer.front.type == tokenType) {
				lexer.stealFront();
				return true;
			} else {
				return false;
			}
		}

		OmToken expectToken(OmToken.Type tokenType) {
			if (lexer.front.type != tokenType) context.error(lexer.front.location, "Expected %s, got '%s'", describeToken(tokenType), lexer.front.lexeme);
			return lexer.stealFront;
		}

		Type makeNode(Type)() {
			auto node = new Type();
			static if(is(Type : OmAstStatement)) {
				if (this.testForToken(OmToken.Type.ud_attribute)) this.parseAttributes();
				node.attributes = this.attributes;
				this.attributes = null;
			}
			node.location = lexer.front.location;
			return node;
		}

		Type makeNode(Type)(OmToken.Type tokenType) {
			auto result = makeNode!Type();
			this.expectToken(tokenType);
			return result;
		}
	}
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
	trinary,
	assignmentOperator
}