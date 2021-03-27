/* 
 * omc: the official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.semantic.insert;

import omc.context;
import omc.parse.ast;
import omc.semantic.symbol;
import omc.semantic.scope_;

class OmSemanticInserter: OmAstVisitor {
	OmContext* context;

	this(ref OmContext context) {
		this.context = &context;
	}

	void visit(OmAstModule node);
	void visit(OmAstAlias node);
	void visit(OmAstDef node);
	void visit(OmAstImport node);
	void visit(OmAstFunction node);
	void visit(OmAstTemplate node);
	void visit(OmAstTypeParamater node);
	void visit(OmAstAliasParamater node);
	void visit(OmAstEnum node);
	void visit(OmAstEnumMember node);
	void visit(OmAstStruct node);
	void visit(OmAstClass node);
	void visit(OmAstInterface node);
	void visit(OmAstIf node);
	void visit(OmAstSwitch node);
	void visit(OmAstCase node);
	void visit(OmAstWhile node);
	void visit(OmAstDoWhile node);
	void visit(OmAstFor node);
	void visit(OmAstForeach node);
	void visit(OmAstWith node);
	void visit(OmAstDelete node);
	void visit(OmAstReturn node);
	void visit(OmAstBreak node);
	void visit(OmAstContinue node);
	void visit(OmAstExpressionStatement node);
	void visit(OmAstIdentifier node);
	void visit(OmAstTuple node);
	void visit(OmAstDispatch node);
	void visit(OmAstSubscript node);
	void visit(OmAstTemplateInstance node);
	void visit(OmAstTypeOf node);
	void visit(OmAstPointerType node);
	void visit(OmAstBinaryOperator node);
	void visit(OmAstUnaryOperator node);
	void visit(OmAstTrinaryOperator node);
	void visit(OmAstAssignmentOperator node);
	void visit(OmAstCall node);
	void visit(OmAstApply node);
	void visit(OmAstCast node);
	void visit(OmAstIs node);
	void visit(OmAstNew node);
	void visit(OmAstArray node);
	void visit(OmAstString node);
	void visit(OmAstChar node);
	void visit(OmAstInteger node);
	void visit(OmAstFloat node);
	void visit(OmAstAttribute node);
}