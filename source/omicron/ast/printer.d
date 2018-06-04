module omicron.ast.printer;

import std.array : Appender;
import std.format : putf = formattedWrite;
import std.string : join;
import omicron.ast.core;

class ASTPrinter: ASTVisitor {
	Appender!string output;
	
	void visit(ASTModule node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		if (node.packageName !is null) output.putf("module %s.%s;", node.packageName.join("."), node.name);
		else output.putf("module %s;", node.name);
		foreach(member; node.members) {
			output.put("\n");
			member.accept(this);
		}
	}
	void visit(ASTEnum node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("enum");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s {", node.name);
		foreach(i, member; node.members) {
			output.put(i != 0 ? ",\n" :"\n");
			member.accept(this);
		}
		output.put("\n}");
	}

	void visit(ASTEnumMember node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put(node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
	}

	void visit(ASTAlias node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("alias");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s", node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
		output.put(";");
	}

	void visit(ASTDef node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("def");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s", node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
		output.put(";");
	}

	void visit(ASTFunction node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("function");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s(", node.name);
		foreach(i, paramater; node.paramaters) {
			output.put(i != 0 ? ", " :"");
			paramater.accept(this);
		}
		output.put(")");
		if (!node.isLinkage) {
			output.put(" {\n");
			foreach(member; node.members) {
				member.accept(this);
				output.put("\n");
			}
			output.put("}");
		} else {
			output.put(";");
		}
	}

	void visit(ASTTemplate node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("template");
		if (!node.isAnonymus) output.putf(" %s", node.name);
		output.put("(");
		foreach(i, paramater; node.paramaters) {
			output.put(i != 0 ? ", " : "");
			paramater.accept(this);
		}
		output.put("(");
		if (node.isAnonymus) {
			node.members[0].accept(this);
		} else {
			output.put(" {\n");
			foreach(member; node.members) {
				member.accept(this);
				output.put("\n");
			}
			output.put("}");
		}
	}

	void visit(ASTTypeParamater node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put(node.name);
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
	}

	void visit(ASTAliasParamater node) {foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("alias");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s", node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
	}

	void visit(ASTDefParamater node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("def");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s", node.name);
		if (node.initializer !is null) {
			output.put(" = ");
			node.initializer.accept(this);
		}
	}

	void visit(ASTStruct node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.putf("struct %s", node.name);
		if (node.baseTypes.length > 0) {
			output.put(": ");
			foreach(i, baseType; node.baseTypes) {
				output.put(i != 0 ? ", " : "");
				baseType.accept(this);
			}
		}
		output.put(" {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTClass node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.putf("class %s", node.name);
		if (node.baseTypes.length > 0) {
			output.put(": ");
			foreach(i, baseType; node.baseTypes) {
				output.put(i != 0 ? ", " : "");
				baseType.accept(this);
			}
		}
		output.put(" {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTInterface node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.putf("interface %s", node.name);
		if (node.baseTypes.length > 0) {
			output.put(": ");
			foreach(i, baseType; node.baseTypes) {
				output.put(i != 0 ? ", " : "");
				baseType.accept(this);
			}
		}
		output.put(" {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTOperator node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("operator");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.putf(" %s(", node.name);
		foreach(i, paramater; node.paramaters) {
			output.put(i != 0 ? ", " :"");
			paramater.accept(this);
		}
		output.put(")");
		if (!node.isLinkage) {
			output.put(" {\n");
			foreach(member; node.members) {
				member.accept(this);
				output.put("\n");
			}
			output.put("}");
		} else {
			output.put(";");
		}
	}

	void visit(ASTImport node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.putf("import %s;", node.fullName.join("."));
	}

	void visit(ASTIf node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("if(");
		node.subject.accept(this);
		output.put(") {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
		if (node.else_ !is null) node.else_.accept(this);
	}

	void visit(ASTElse node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("else {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTForeach node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("foreach(");
		foreach(i, initializer; node.initializers) {
			output.put(i != 0 ? ", " : "");
			initializer.accept(this);
		}
		output.put(";");
		node.subject.accept(this);
		output.put(") {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTFor node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("for(");
		if (node.initializer !is null) node.initializer.accept(this);
		output.put(";");
		if (node.subject !is null) node.subject.accept(this);
		output.put(";");
		if (node.step !is null) node.step.accept(this);
		output.put(") {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTWhile node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("while(");
		node.subject.accept(this);
		output.put(") {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTSwitch node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("switch(");
		node.subject.accept(this);
		output.put(") {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTCase node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("case(");
		foreach(i, subject; node.subjects) {
			output.put(i != 0 ? ", " : "");
			subject.accept(this);
		}
		output.put(")");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
	}

	void visit(ASTDoWhile node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("do {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("} while(");
		node.subject.accept(this);
		output.put(");");
	}

	void visit(ASTWith node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("with");
		if (node.type !is null) {
			output.put(":");
			node.type.accept(this);
		}
		output.put("(");
		node.subject.accept(this);
		output.put(") {\n");
		foreach(member; node.members) {
			member.accept(this);
			output.put("\n");
		}
		output.put("}");
	}

	void visit(ASTDelete node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("delete ");
		node.subject.accept(this);
		output.put(";");
	}

	void visit(ASTReturn node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("return ");
		if (node.subject !is null) node.subject.accept(this);
		output.put(";");
	}

	void visit(ASTBreak node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("break;");
	}

	void visit(ASTContinue node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		output.put("continue;");
	}

	void visit(ASTExpressionStatement node) {
		foreach(attribute; node.attributes) {
			attribute.accept(this);
			output.put(" ");
		}
		node.subject.accept(this);
		output.put(";");
	}

	void visit(ASTIdentifier node) {
		output.put(node.name);
	}

	void visit(ASTTuple node) {
		output.put("(");
		foreach(i, member; node.members) {
			output.put(i != 0 ? ", " : "");
			member.accept(this);
		}
		output.put(")");
	}

	void visit(ASTDispatch node) {
		node.subject.accept(this);
		output.putf(".%s", node.name);
	}

	void visit(ASTSubscript node) {
		node.subject.accept(this);
		output.put("[");
		foreach(i, argument; node.arguments) {
			output.put(i != 0 ? ", " : "");
			argument.accept(this);
		}
		output.put("]");
	}

	void visit(ASTTemplateInstance node) {
		node.subject.accept(this);
		output.put(":(");
		foreach(i, argument; node.arguments) {
			output.put(i != 0 ? ", " : "");
			argument.accept(this);
		}
		output.put(")");
	}

	void visit(ASTTypeOf node) {
		output.put("typeof(");
		node.subject.accept(this);
		output.put(")");
	}

	void visit(ASTPointerType node) {
		node.subject.accept(this);
		output.put("*");
	}

	void visit(ASTBinaryOperator node) {
		node.lhs.accept(this);
		final switch(node.operator) with(ASTBinaryOperator.Operator) {
			case add:
				output.put(" + ");
				break;

			case subtract:
				output.put(" - ");
				break;

			case multiply:
				output.put(" * ");
				break;

			case divide:
				output.put(" / ");
				break;

			case modulo:
				output.put(" % ");
				break;

			case concat:
				output.put(" ~ ");
				break;

			case equal:
				output.put(" == ");
				break;

			case notEqual:
				output.put(" != ");
				break;

			case lessThan:
				output.put(" < ");
				break;

			case greaterThan:
				output.put(" > ");
				break;

			case lessThanEqual:
				output.put(" <= ");
				break;

			case greaterThanEqual:
				output.put(" >= ");
				break;

			case and:
				output.put(" && ");
				break;

			case or:
				output.put(" || ");
				break;

			case xor:
				output.put(" ## ");
				break;

			case bitwiseAnd:
				output.put(" & ");
				break;

			case bitwiseOr:
				output.put(" | ");
				break;

			case bitwiseXor:
				output.put(" # ");
				break;

			case bitwiseShiftLeft:
				output.put(" << ");
				break;

			case bitwiseShiftRight:
				output.put(" >> ");
				break;

			case slice:
				output.put(" .. ");
				break;
		}
		node.rhs.accept(this);
	}

	void visit(ASTUnaryOperator node) {
		final switch(node.operator) with(ASTUnaryOperator.Operator) {
			case increment:
				node.subject.accept(this);
				output.put(" ++ ");
				break;

			case decrement:
				node.subject.accept(this);
				output.put(" -- ");
				break;

			case posative:
				node.subject.accept(this);
				output.put(" + ");
				break;

			case negative:
				node.subject.accept(this);
				output.put(" - ");
				break;

			case enreference:
				node.subject.accept(this);
				output.put(" & ");
				break;

			case dereference:
				node.subject.accept(this);
				output.put(" * ");
				break;

			case not:
				node.subject.accept(this);
				output.put(" ! ");
				break;

			case bitwiseNot:
				node.subject.accept(this);
				output.put(" ~ ");
				break;

			case postIncrement:
				node.subject.accept(this);
				output.put("++");
				break;

			case postDecrement:
				node.subject.accept(this);
				output.put("--");
				break;
		}
	}

	void visit(ASTTinaryOperator node) {
		node.subject.accept(this);
		output.put(" ? (");
		node.lhs.accept(this);
		output.put(") : (");
		node.rhs.accept(this);
		output.put(")");
	}

	void visit(ASTAssignmentOperator node) {
		node.subject.accept(this);
		final switch(node.operator) with(ASTAssignmentOperator.Operator) {
			case assign:
				output.put(" = ");
				break;

			case add:
				output.put(" += ");
				break;

			case subtract:
				output.put(" -= ");
				break;

			case multiply:
				output.put(" *= ");
				break;

			case divide:
				output.put(" /= ");
				break;

			case modulo:
				output.put(" %= ");
				break;

			case concat:
				output.put(" ~= ");
				break;

			case and:
				output.put(" &= ");
				break;

			case or:
				output.put(" |= ");
				break;

			case xor:
				output.put(" #= ");
				break;
		}
		node.assignment.accept(this);
	}

	void visit(ASTCall node) {
		node.subject.accept(this);
		output.put("(");
		foreach(i, argument; node.arguments) {
			output.put(i != 0 ? ", " : "");
			argument.accept(this);
		}
		output.put(")");
	}

	void visit(ASTApply node) {
		node.subject.accept(this);
		output.putf(".?%s", node.name);
	}

	void visit(ASTCast node) {
		output.put("cast:");
		node.type.accept(this);
		output.put("(");
		node.subject.accept(this);
		output.put(")");
	}

	void visit(ASTIs node) {
		node.lhs.accept(this);
		output.put(" is ");
		node.rhs.accept(this);
	}

	void visit(ASTNew node) {
		output.put("cast:");
		node.type.accept(this);
		output.put("(");
		foreach(i, argument; node.arguments) {
			output.put(i != 0 ? ", " : "");
			argument.accept(this);
		}
		output.put(")");
	}

	void visit(ASTArray node) {
		output.put("[");
		foreach(i, member; node.members) {
			output.put(i != 0 ? ", " : "");
			member.accept(this);
		}
		output.put("]");
	}

	void visit(ASTString node) {
		output.putf("`%s`", node.literal);
	}

	void visit(ASTChar node) {
		output.putf("'%s'", node.literal);
	}

	void visit(ASTInteger node) {
		output.putf("%s", node.literal);
	}

	void visit(ASTFloat node) {
		output.putf("%s", node.literal);
	}

	void visit(ASTAttribute node) {
		output.putf("@%s", node.name);
		if (node.arguments.length > 0) {
			output.put("(");
			foreach(i, argument; node.arguments) {
				output.put(i != 0 ? ", " : "");
				argument.accept(this);
			}
			output.put(")");
		}
	}
}
