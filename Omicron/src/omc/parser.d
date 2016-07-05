module omc.parser;

import omc.lexer,
       omc.ast,
       omc.errors,
       omc.utils : Stack, fileName;

alias TokenList = DList!Token;
alias AStack = Stack!ASTNode;

ASTModule parseModule(TokenList list, string file)
{
    auto module_ = new ASTModule(list.front().loc);
    auto stack = new AStack();
    stack.push(module_);
    if (list.test(TokenType.tk_module))
    {
        module_.name = parseQuantifiedName(list,stack);
        list.expect(TokenType.tk_term);
    }
    else
        module_.name = fileName(file);
    while(!list.empty())
        module_.moduleBody ~= parseDecl(list,stack);
    stack.pop();
    return module_;
}

ASTImport parseImport(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_import);
    return new ASTImport(stack.peek(),next.loc,parseQuantifiedName(list,stack),
        properties);
}

ASTDef parseDef(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_def);
    list.expect(TokenType.tk_colon);
    auto type = parseSymbolRef(list,stack);
    auto name = list.expect(TokenType.tk_id).text;
    if (list.test(TokenType.tk_ass))
        return new ASTDef(stack.peek(),next.loc,name,type,parseExp(list,stack)
            ,properties);
    else
        return new ASTDef(stack.peek(),next.loc,name,type,null,properties);
}

ASTFunction parseFunc(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_func);
    list.expect(TokenType.tk_colon);
    auto type = parseSymbolRef(list,stack);
    auto name = list.expect(TokenType.tk_id).text;
    auto func = new ASTFunction(stack.peek(),next.loc,name,type,properties);
    stack.push(func);
    func.args = parseParamaterList!parseDef(list,stack);
    func.funcBody = parseStatementBlock(list,stack);
    stack.pop();
    return func;
}

ASTTemplate parseTemplate(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_template);
    auto name = list.expect(TokenType.tk_id).text;
    auto temp = new ASTTemplate(stack.peek(),next.loc,name,properties);
    stack.push(temp);
    temp.args = parseParamaterList!_name(list,stack);
    temp.templateBody = parseDeclBlock(list,stack);
    stack.pop();
    return temp;
}

ASTStruct parseStruct(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_template);
    auto name = list.expect(TokenType.tk_id).text;
    auto struc = new ASTStruct(stack.peek(),next.loc,name,properties);
    stack.push(struc);
    struc.structBody = parseDeclBlock(list,stack);
    stack.pop();
    return struc;
}

ASTClass parseClass(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_template);
    auto name = list.expect(TokenType.tk_id).text;
    auto clazz = new ASTClass(stack.peek(),next.loc,name,properties);
    if (list.test(TokenType.tk_inherits))
        clazz.inherits = parseInheritsList(list,stack);
    stack.push(clazz);
    clazz.classBody = parseDeclBlock(list,stack);
    stack.pop();
    return clazz;
}

ASTInterface parseInterface(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.expect(TokenType.tk_template);
    auto name = list.expect(TokenType.tk_id).text;
    auto iface = new ASTInterface(stack.peek(),next.loc,name,properties);
    stack.push(iface);
    if (list.test(TokenType.tk_inherits))
        iface.inherits = parseInheritsList(list,stack);
    iface.interfaceBody = parseDeclBlock(list,stack);
    stack.pop();
    return iface;
}

ASTFor parseFor(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_for);
    auto for_ = new ASTFor(stack.peek(),next.loc);
    stack.push(for_);
    list.expect(TokenType.tk_lparen);
    if (list.test(TokenType.tk_def))
        for_.def = parseDef(list,stack);
    //TODO: special case for type quantifiers
    list.expect(TokenType.tk_term);
    if (list.front().type != TokenType.tk_term)
        for_.cond = parseExp(list,stack);
    list.expect(TokenType.tk_term);
    if (list.front().type != TokenType.tk_rparen)
        for_.exp = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    for_.forBody = parseStatementBlock(list,stack);
    stack.pop();
    return for_;
}

ASTForeach parseForeach(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_foreach);
    auto foreach_ = new ASTForeach(stack.peek(),next.loc);
    stack.push(foreach_);
    list.expect(TokenType.tk_lparen);
    foreach_.defs = parseDelimitedList!parseDef(list,stack,TokenType.tk_sep);
    list.expect(TokenType.tk_term);
    foreach_.exp = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    foreach_.foreachBody = parseStatementBlock(list,stack);
    stack.pop();
    return foreach_;
}

ASTWhile parseWhile(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_foreach);
    auto whle = new ASTWhile(stack.peek(),next.loc);
    stack.push(whle);
    list.expect(TokenType.tk_lparen);
    whle.cond = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    whle.whileBody = parseStatementBlock(list,stack);
    stack.pop();
    return whle;
}

ASTDo parseDo(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_foreach);
    auto do_ = new ASTDo(stack.peek(),next.loc);
    stack.push(do_);
    do_.doBody = parseStatementBlock(list,stack);
    list.expect(TokenType.tk_lparen);
    do_.cond = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    stack.pop();
    return do_;
}

ASTIf parseIf(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_if);
    auto if_ = new ASTIf(stack.peek(),next.loc);
    stack.push(if_);
    list.expect(TokenType.tk_lparen);
    if_.cond = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    if_.ifBody = parseStatementBlock(list,stack);
    stack.pop();
    if (list.front().type == TokenType.tk_else)
        if_.else_ = parseElse(list,stack);
    return if_;
}

ASTElse parseElse(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_else);
    auto else_ = new ASTElse(stack.peek(),next.loc);
    stack.push(else_);
    else_.elseBody = parseStatementBlock(list,stack);
    stack.pop();
    return else_;
}
 
ASTSwitch parseSwitch(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_switch);
    auto switch_ = new ASTSwitch(stack.peek(),next.loc);
    stack.push(switch_);
    list.expect(TokenType.tk_lparen);
    switch_.cond = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    switch_.cases = parseCaseBlock(list,stack);
    stack.pop();
    return switch_;
}

ASTCase parseCase(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_case);
    auto case_ = new ASTCase(stack.peek(),next.loc);
    stack.push(case_);
    list.expect(TokenType.tk_lparen);
    if (list.test(TokenType.tk_else))
        case_.elseCase = true;
    else
        case_.exp = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    list.expect(TokenType.tk_colon);
    case_.caseBody = parseStatementBlock(list,stack);
    return case_;
}

ASTNew parseNew(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_new);
    auto type = parseSymbolRef(list,stack);
    auto new_ = new ASTNew(stack.peek(),next.loc,type,
        parseParamaterList!parseExp(list,stack));
    return new_;
}

ASTCast parseCast(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_cast);
    list.expect(TokenType.tk_colon);
    auto type = parseSymbolRef(list,stack);
    list.expect(TokenType.tk_lparen);
    auto exp = parseExp(list,stack);
    list.expect(TokenType.tk_rparen);
    return new ASTCast(stack.peek(),next.loc,type,exp);
}

ASTDecl parseDecl(TokenList list, AStack stack, string[] properties = null)
{
    auto next = list.front();
    switch(next.type)
    {
        case TokenType.tk_import:
            auto result = parseImport(list,stack,properties);
            list.expect(TokenType.tk_term);
            return result;
        case TokenType.tk_def:
            auto result = parseDef(list,stack,properties);
            list.expect(TokenType.tk_term);
            return result;
        case TokenType.tk_func:
            return parseFunc(list,stack,properties);
        case TokenType.tk_template:
            return parseTemplate(list,stack,properties);
        case TokenType.tk_struct:
            return parseStruct(list,stack,properties);
        case TokenType.tk_class:
            return parseClass(list,stack,properties);
        case TokenType.tk_interface:
            return parseInterface(list,stack,properties);
        case TokenType.tk_prop:
            return parseDecl(list,stack,parsePropertiesList(list,stack));
        default:
            throw new ParseError(next.loc,"Unrecognised Decleration: ",next.text);
    }
}

ASTNode parseStatement(TokenList list, AStack stack)
{
    auto next = list.front();
    switch(next.type)
    {
        case TokenType.tk_import:
        case TokenType.tk_def:
        case TokenType.tk_func:
        case TokenType.tk_template:
        case TokenType.tk_struct:
        case TokenType.tk_class:
        case TokenType.tk_interface:
        case TokenType.tk_prop:
            return parseDecl(list,stack,parsePropertiesList(list,stack));
        case TokenType.tk_for:
            return parseFor(list,stack);
        case TokenType.tk_foreach:
            return parseForeach(list,stack);
        case TokenType.tk_while:
            return parseWhile(list,stack);
        case TokenType.tk_do:
            return parseDo(list,stack);
        case TokenType.tk_if:
            return parseIf(list,stack);
        case TokenType.tk_switch:
            return parseSwitch(list,stack);
        default:
            return parseEffectiveExp(list,stack);
    }
}

ASTNode parseEffectiveExp(TokenList list, AStack stack)
{
    auto exp = parseExp(list,stack);
    list.expect(TokenType.tk_term);
    if(exp.classinfo == ASTCallExp.classinfo ||
       exp.classinfo == ASTAssign.classinfo)
       return exp;
    else
       throw new ParseError(exp.loc,"Expression ",exp," has no effect");
}

ASTNode parseExp(TokenList list, AStack stack)
{
    auto next = list.front();
    switch(next.type)
    {
        case TokenType.tk_add:
        case TokenType.tk_sub:
        case TokenType.tk_inc:
        case TokenType.tk_dec:
            list.removeFront();
            return parseExp(list,stack,new ASTUnaryExp(stack.peek(),next.loc,
                next.text,parseExp(list,stack),true));
        case TokenType.tk_iconst:
            list.removeFront();
            return parseExp(list,stack,new ASTIntegerLiteral(stack.peek(),
                next.loc,next.text));
        case TokenType.tk_fconst:
            list.removeFront();
            return parseExp(list,stack,new ASTFloatLiteral(stack.peek(),
                next.loc,next.text));
        case TokenType.tk_cconst:
            list.removeFront();
            return parseExp(list,stack,new ASTCharacterLiteral(stack.peek(),
                next.loc,next.text));
        case TokenType.tk_sconst:
            list.removeFront();
            return parseExp(list,stack,new ASTStringLiteral(stack.peek(),
                next.loc,next.text));
        case TokenType.tk_id:
            list.removeFront();
            return parseExp(list,stack,new ASTIdentifier(stack.peek(),next.loc,
                next.text));
        case TokenType.tk_lbracket:
            return parseExp(list,stack,new ASTArrayLiteral(stack.peek(),next.loc,
                parseIndexList!parseExp(list,stack)));
        case TokenType.tk_lparen:
            list.expect(TokenType.tk_lparen);
            auto exp = parseExp(list,stack);
            list.expect(TokenType.tk_rparen);
            return exp;
        case TokenType.tk_new:
            return parseExp(list,stack,parseNew(list,stack));
        case TokenType.tk_cast:
            return parseExp(list,stack,parseCast(list,stack));
        case TokenType.tk_def:
            return parseDef(list,stack);
        case TokenType.tk_prop:
            return parseDef(list,stack,parsePropertiesList(list,stack));
        default:
            throw new ParseError(next.loc,"Unrecognised expession: ",next.text);
    }
}

ASTNode parseExp(TokenList list, AStack stack, ASTNode exp)
{
    auto next = list.front();
    switch(next.type)
    {
        case TokenType.tk_concat:
        case TokenType.tk_add:
        case TokenType.tk_sub:
        case TokenType.tk_mul:
        case TokenType.tk_div:
        case TokenType.tk_mod:
        case TokenType.tk_geq:
        case TokenType.tk_leq:
        case TokenType.tk_gr:
        case TokenType.tk_le:
        case TokenType.tk_eq:
            list.removeFront();
            return parseExp(list,stack,new ASTBinaryExp(stack.peek(),next.loc,
                exp,next.text,parseExp(list,stack)));
                case TokenType.tk_inc:
        case TokenType.tk_dec:
            list.removeFront();
            return parseExp(list,stack,new ASTUnaryExp(stack.peek(),next.loc,
                next.text,parseExp(list,stack),false));
        case TokenType.tk_lparen:
            return parseExp(list,stack,new ASTCallExp(stack.peek(),next.loc,
                exp,parseParamaterList!parseExp(list,stack)));
        case TokenType.tk_lbracket:
            return parseExp(list,stack,new ASTIndexExp(stack.peek(),next.loc,
                exp,parseIndexList!parseExp(list,stack)));
        case TokenType.tk_dot:
            list.removeFront();
            return parseExp(list,stack,new ASTDispatch(stack.peek(),next.loc,
                exp, list.expect(TokenType.tk_id).text));
        case TokenType.tk_ass:
        case TokenType.tk_addass:
        case TokenType.tk_subass:
        case TokenType.tk_mulass:
        case TokenType.tk_divass:
        case TokenType.tk_modass:
        case TokenType.tk_conass:
            list.removeFront();
            return parseExp(list,stack,new ASTAssign(stack.peek(),next.loc,exp,next.text,
                parseExp(list,stack)));
        default:
            return exp;
    }
}

ASTDecl[] parseDeclBlock(TokenList list, AStack stack)
{
    auto next = list.front();
    if (!list.test(TokenType.tk_lbrace))
        return [parseDecl(list,stack)];
    else
    {
        ASTDecl[] decls;
        for(auto nnext = list.front();!list.empty;nnext = list.front())
        {
            if (nnext.type == TokenType.tk_rbrace)
            {
                list.removeFront();
                return decls;
            }
            else
                decls ~= parseDecl(list,stack);
        }
        throw new ParseError(next.loc,"Expected } not <EOF> to close ",
            stack.peek().getDescription()," on line: ",stack.peek().loc.line);
    }
}

ASTNode[] parseStatementBlock(TokenList list, AStack stack)
{
    auto next = list.front();
    if (!list.test(TokenType.tk_lbrace))
        return [parseStatement(list,stack)];
    else
    {
        ASTNode[] statements;
        for(auto nnext = list.front();!list.empty;nnext = list.front())
        {
            if (nnext.type == TokenType.tk_rbrace)
            {
                list.removeFront();
                return statements;
            }
            else
                statements ~= parseStatement(list,stack);
        }
        throw new ParseError(next.loc,"Expected } not <EOF> to close ",
            stack.peek().getDescription()," on line: ",stack.peek().loc.line);
    }
}

ASTCase[] parseCaseBlock(TokenList list, AStack stack)
{
    auto next = list.front();
    if (!list.test(TokenType.tk_lbrace))
        return [parseCase(list,stack)];
    else
    {
        ASTCase[] cases;
        for(auto nnext = list.front();!list.empty;nnext = list.front())
        {
            if (nnext.type == TokenType.tk_rbrace)
            {
                list.removeFront();
                return cases;
            }
            else
                cases ~= parseCase(list,stack);
        }
        throw new ParseError(next.loc,"Expected } not <EOF> to close ",
            stack.peek().getDescription()," on line: ",stack.peek().loc.line);
    }
}

ASTNode parseSymbolRef(TokenList list, AStack stack)
{
    auto next = list.expect(TokenType.tk_id);
    return parseSymbolRef(list,stack,new ASTIdentifier(stack.peek(),next.loc,
        next.text));
}

ASTNode parseSymbolRef(TokenList list, AStack stack, ASTNode sym)
{
    auto next = list.front();
    if (list.test(TokenType.tk_dot))
        return parseSymbolRef(list,stack,new ASTDispatch(stack.peek(),next.loc,
            sym,list.expect(TokenType.tk_id).text));
    else if (list.test(TokenType.tk_colon))
        return parseSymbolRef(list,stack,new ASTTemplateInstance(stack.peek(),
            next.loc,sym,parseParamaterList!parseSymbolRef(list,stack)));
    else
        return sym;
}

auto parseParamaterList(alias fun)(TokenList list, AStack stack)
{
    return parseList!fun(list,stack,TokenType.tk_lparen,TokenType.tk_sep,
        TokenType.tk_rparen);
}

auto parseIndexList(alias fun)(TokenList list, AStack stack)
{
    return parseList!fun(list,stack,TokenType.tk_lbracket,TokenType.tk_sep,
        TokenType.tk_rbracket);
}

auto parseInheritsList(TokenList list,AStack stack)
{
    return parseDelimitedList!parseSymbolRef(list,stack,TokenType.tk_sep);
}

auto parseList(alias fun)(TokenList list, AStack stack,
    TokenType front,TokenType middle, TokenType back)
{
    import std.traits;
    ReturnType!(fun)[] result;
    list.expect(front);
    for(auto next = list.front();!list.empty;next = list.front())
    {
        if (next.type == back)
        {
            list.removeFront();
            break;
        }
        else
        {
            result ~= fun(list,stack);
            list.expect(middle);
        }
    }
    return result;
}

auto parseDelimitedList(alias fun)(TokenList list, AStack stack, TokenType delimiter)
{
    import std.traits;
    ReturnType!(fun)[] result;
    for(auto next = list.front;!list.empty;next = list.front())
    {
        result ~= fun(list,stack);
        if (list.test(delimiter))
        {
            list.removeFront();
            break;
        }
    }
    return result;
}

auto _name(TokenList list, AStack _) { return list.expect(TokenType.tk_id).text; }

string parseQuantifiedName(TokenList list, AStack stack)
{
    import std.array : join;
    return parseDelimitedList!_name(list,stack,TokenType.tk_dot).join(".");
}

string[] parsePropertiesList(TokenList list, AStack stack)
{
    if(list.front().type != TokenType.tk_prop)
        return null;
    else
    {
        string[] result;
        for(auto next = list.front();!list.empty;next = list.front())
        {
            if (list.test(TokenType.tk_prop))
                result ~= list.expect(TokenType.tk_id).text;
            else
                break;
        }
        return result;
    }
}

Token expect(TokenList list, TokenType type)
{
    auto next = list.front();
    if (next.type == type)
    {
        list.removeFront();
        return next;
    }
    else
        throw new ParseError(next.loc,"Expected '",getTokenNameFromType(type),
            "', got '",next.text,"'");
}

bool test(TokenList list, TokenType type)
{
    auto next = list.front();
    if (next.type == type)
    {
        list.removeFront();
        return true;
    }
    else
        return false;
}
