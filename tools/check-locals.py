#!/usr/bin/env python3
"""Luau's ceiling is 200 locals live at once inside one function, and the main chunk of a
hub script is one function. Blowing it is a compile error the executor reports at whatever
line happened to be last, which is nowhere near the line that caused it -- so this counts
them instead of finding out the hard way.

    python3 tools/check-locals.py Scripts/STE.lua

What it counts, per function body (nested functions counted separately): named locals,
`local function` names, loop control variables and parameters, with registers released at
the end of every block the way the compiler releases them. It is deliberately a little
pessimistic -- a branch of an `if` frees its locals at `elseif`/`else`, which is modelled,
but nothing else clever is -- so a file it passes compiles and a file near the line is
worth trimming.

Exit code 1 when anything is at or over the limit.
"""
import re, sys, os


def strip(src):
    out, i, n = [], 0, len(src)
    while i < n:
        m = re.match(r'--\[(=*)\[', src[i:])
        if m:
            close = ']' + m.group(1) + ']'
            j = src.find(close, i); j = n if j < 0 else j + len(close)
            out.append(re.sub(r'[^\n]', ' ', src[i:j])); i = j; continue
        if src.startswith('--', i):
            j = src.find('\n', i); j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j; continue
        m = re.match(r'\[(=*)\[', src[i:])
        if m:
            close = ']' + m.group(1) + ']'
            j = src.find(close, i); j = n if j < 0 else j + len(close)
            out.append(re.sub(r'[^\n]', ' ', src[i:j])); i = j; continue
        c = src[i]
        if c in '"\'':
            j = i + 1
            while j < n:
                if src[j] == '\\': j += 2; continue
                if src[j] == c: j += 1; break
                if src[j] == '\n': break
                j += 1
            out.append(' ' * (j - i)); i = j; continue
        out.append(c); i += 1
    return ''.join(out)

path = sys.argv[1]
clean = strip(open(path).read())
line_of = lambda p: clean.count('\n', 0, p) + 1

TOK = re.compile(r"""
   (?P<localfn>\blocal\s+function\s+(?P<lfname>[A-Za-z_]\w*)\s*\((?P<lfparams>[^)]*)\))
 | (?P<func>\bfunction\b\s*(?P<fname>[A-Za-z_][\w.:]*)?\s*\((?P<params>[^)]*)\))
 | (?P<local>\blocal\b(?![ \t]*function\b)(?P<names>(?:\s*[A-Za-z_]\w*\s*,)*\s*[A-Za-z_]\w*))
 | (?P<forin>\bfor\b(?P<vars>[^=\n]*?)\bin\b)
 | (?P<fornum>\bfor\b\s+(?P<var>[A-Za-z_]\w*)\s*=)
 | (?P<branch>\b(?:elseif|else)\b)
 | (?P<ifw>\b(?:if|while)\b)
 | (?P<do>\bdo\b)
 | (?P<repeat>\brepeat\b)
 | (?P<until>\buntil\b)
 | (?P<end>\bend\b)
""", re.X)

frames = [dict(name='<main chunk>', line=1, count=0, peak=0, peak_line=1, peak_why='start', marks=[])]
blocks = ['func']          # what each open block is: 'func' or 'block'
done = []
pending_do = 0             # a for/while header is open, its `do` must not push

def open_scope():
    frames[-1]['marks'].append(frames[-1]['count'])

def close_scope():
    f = frames[-1]
    if f['marks']:
        f['count'] = f['marks'].pop()

TRACE = []
def bump(k, why, pos):
    f = frames[-1]
    f['count'] += k
    if len(frames) == 1:
        TRACE.append((line_of(pos), f['count'], k, why))
    if f['count'] > f['peak']:
        f.update(peak=f['count'], peak_line=line_of(pos), peak_why=why)

def push_func(name, params, pos):
    n = len([p for p in params.split(',') if p.strip()])
    if ':' in name: n += 1
    frames.append(dict(name=name, line=line_of(pos), count=n, peak=n,
                       peak_line=line_of(pos), peak_why=f'{n} params', marks=[]))
    blocks.append('func')

for m in TOK.finditer(clean):
    g, pos = m.groupdict(), m.start()

    if g['localfn'] is not None:
        bump(1, 'local function ' + g['lfname'], pos)
        push_func(g['lfname'], g['lfparams'], pos)
    elif g['func'] is not None:
        push_func(g['fname'] or '<anonymous>', g['params'], pos)
    elif g['local'] is not None:
        names = [x for x in g['names'].split(',') if x.strip()]
        bump(max(len(names), 1), ('local' + g['names'])[:56].strip(), pos)
    elif g['forin'] is not None:
        # the control variables belong to the loop body's own scope, so the scope opens first
        # and they go away with it
        blocks.append('block'); open_scope(); pending_do += 1
        bump(max(len([x for x in g['vars'].split(',') if x.strip()]), 1), 'for-in vars', pos)
    elif g['fornum'] is not None:
        blocks.append('block'); open_scope(); pending_do += 1
        bump(1, 'for ' + g['var'], pos)
    elif g['branch'] is not None:
        # each branch of an if is its own scope: the previous branch's locals are freed
        close_scope(); open_scope()
    elif g['ifw'] is not None:
        blocks.append('block'); open_scope()
        if m.group(0) == 'while': pending_do += 1
    elif g['do'] is not None:
        if pending_do > 0: pending_do -= 1     # belongs to the for/while just opened
        else:
            blocks.append('block'); open_scope()
    elif g['repeat'] is not None:
        blocks.append('block'); open_scope()
    elif g['until'] is not None:
        if blocks and blocks[-1] == 'block':
            blocks.pop(); close_scope()
    elif g['end'] is not None:
        if not blocks:
            print(f"!! stray end at line {line_of(pos)}"); continue
        popped = blocks.pop()
        if popped == 'block':
            close_scope()
        if popped == 'func':
            if len(frames) > 1: done.append(frames.pop())
            else: print(f"!! function underflow at line {line_of(pos)}")

done.extend(reversed(frames))
left = blocks[1:]
if left or len(frames) != 1:
    print(f"!! parse did not balance: blocks left {left}, frames {[f['name'] for f in frames]}")
    print()
if os.environ.get('TRACE'):
    for ln, c, k, why in TRACE:
        print(f"  line {ln:>5}  live {c:>4}  (+{k})  {why}")
    print()
LIMIT = 200

print(f"{'peak':>5}  {'line':>6}  function")

worst = 0

for f in sorted(done, key=lambda f: -f['peak'])[:15]:
    worst = max(worst, f['peak'])
    room = LIMIT - f['peak']
    flag = '  <-- AT OR OVER THE LIMIT' if f['peak'] >= LIMIT else (f'  ({room} left)' if room <= 25 else '')
    print(f"{f['peak']:>5}  {f['line']:>6}  {f['name']}   peak@{f['peak_line']} ({f['peak_why']}){flag}")

print()
print(f"limit {LIMIT}, worst {worst}, headroom {LIMIT - worst}")

sys.exit(1 if worst >= LIMIT else 0)
