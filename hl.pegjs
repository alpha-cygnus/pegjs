S = __ h:statement t:(ssep s:statement {s})* ssep? __ { [h].concat(t).join(';\n') }

ssep = _ ';' __ / _ CRLF __

statement = assign / expr

assign = n:lname as:largs _ '=' __ e:expr {
	return (n.match(/^\w+$/) ? 'const ' + n : '$OPS[\'' + n + '\']')
	    + ' = ' + as + e
}

largs = as:(id/lodash)* {as.map((a, i) => (a === '_' ? '$' + i : a) + ' => ').join('')}

lname = id
	/ '(' op: BINOP ')' {op}

expr = a:app tail:(op:binop b:app { [op, b] })* {
	let result = a;
    for (const [op, b] of tail) {
    	if (op === '$') {
        	result = result + '(' + b + ')';
        } else {
          const f = op.match(/^\w+$/) ? op : '$OPS[\'' + op + '\']';
          result = f + '(' + a + ')(' + b + ')';
        }
    }
    return result;
}

binop =
	_ op:$(BINOP) _ { op }
    / _ '`' id:id '`' _ { id }

app = f:prim as:prim* { as.length ? f + '(' + as.join(')(') + ')' : f } / num

prim = num
    / id:Id { `new ${id}` }
    / id
    / _'('_ e:expr _')'_ { e }
    / _'['_ l:expr_list? _']'_ { '[' + (l || []).join(', ') + ']'}
    / _'\\'_ as:largs _'='_ e:expr { as + e }
    
expr_list = h:expr t:(_','__ e:expr {e})* {[h].concat(t)} 

id = _ id:$(LC (LTR/DIG)*) _ { id }
Id = _ id:$(UC (LTR/DIG)*) _ { id }
num = _ n:$(FLOAT) _ { parseFloat(n) }
lodash = _ '_' _ {'_'}

UC = [A-Z]
LC = [a-z]
LTR = UC/LC
DIG = [0-9]
INT = DIG+
BINCHAR = '+'/'-'/'*'/'>'/'$'
BINOP = BINCHAR+
FLOAT = ('+'/'-')? INT ('.' INT)? / '.' INT
SPACE = ' '/'\t'
CRLF = '\n'/'\r'
_ = SPACE*
__ = (SPACE/CRLF)*
