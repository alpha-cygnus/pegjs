{
    const binOpVar = op => `$OPS['${op}']`;
    const pr = e => e.toString().match(/^\(.*\)$/) ? e : `(${e})`;
    const binExpr = (op, a, b) => {
        if (op.match(/^\w+$/)) {
            return `${op}(${a})(${b})`;
        }
        if (op === '$') return `${a}(${b})`;
        if (['+', '-', '/', '*'].includes(op)) return `${a} ${op} ${b}`;
        return `${binOpVar(op)}(${a})(${b})`;
    }
}

S = __ h:statement t:(ssep s:statement {s})* ssep? __ { [h].concat(t).join(';\n') }

ssep = _ ';' __ / _ CRLF __

statement = assign / expr

assign = n:lname as:largs _ '=' __ e:expr { `${n} = ${as}${e}` }

largs = as:(id/lodash)* {as.map((a, i) => (a === '_' ? '$' + i : a) + ' => ').join('')}

lname = id:id { `const ${id}`}
	/ open op:BINOP close { binOpVar(op) }

expr = a:app tail:(op:binop b:app { [op, b] })* { tail.reduce((a, [op, b]) => binExpr(op, a, b), a) }

binop =
	_ op:$(BINOP) _ { op }
    / _ '`' id:id '`' _ { id }

app = f:prim as:prim* { f + as.map(pr).join('') }
    / num

prim = num
    / id:Id { `new ${id}` }
    / id
    / open op:BINOP close { binOpVar(op) }
    / open e:expr close { pr(e) }
    / _'['_ l:expr_list? _']'_ { '[' + (l || []).join(', ') + ']'}
    / _'\\'_ as:largs _'='_ e:expr { as + e }
    
expr_list = h:expr t:(_','__ e:expr {e})* {[h].concat(t)} 

id = _ id:$(LC (LTR/DIG)*) _ { id }
Id = _ id:$(UC (LTR/DIG)*) _ { id }
num = _ n:$(FLOAT) _ { n }
lodash = _'_'_ {'_'}

open = _'('_
close = _')'_

UC = [A-Z]
LC = [a-z]
LTR = UC/LC
DIG = [0-9]
INT = DIG+
BINCHAR = '+'/'-'/'*'/'>'/'$'
BINOP = $(BINCHAR+)
FLOAT = ('+'/'-')? INT ('.' INT)? / '.' INT
SPACE = ' '/'\t'
CRLF = '\n'/'\r'
_ = SPACE*
__ = (SPACE/CRLF)*
