"""Remove `const` keywords that became invalid after AppColors surface/text
colors turned into runtime getters. For each `invalid_constant` /
`non_constant_*_element` error the analyzer reports, we delete every `const`
keyword whose constructor/literal encloses the flagged position (a value is
illegal-const if ANY enclosing context is const, so all enclosing consts go).

Usage: python tool/fix_const.py <analyze_dir>  (run from repo root)
Idempotent; re-run until it reports 0 fixes.
"""
import re
import subprocess
import sys
import os

CODES = {
    'invalid_constant',
    'const_with_non_constant_argument',
    'non_constant_list_element',
    'non_constant_map_element',
    'non_constant_map_key_element',
    'non_constant_set_element',
}
LOC_RE = re.compile(r'^(.+):(\d+):(\d+)$')


def analyze(target):
    res = subprocess.run(['flutter', 'analyze', target],
                         capture_output=True, text=True, shell=True)
    out = res.stdout + res.stderr
    errs = {}
    for line in out.splitlines():
        s = line.strip()
        if not s.startswith('error'):
            continue
        parts = s.split(' - ')
        if len(parts) < 3:
            continue
        code = parts[-1].strip()
        if code not in CODES:
            continue
        m = LOC_RE.match(parts[-2].strip())
        if not m:
            continue
        path, ln, col = m.group(1), int(m.group(2)), int(m.group(3))
        errs.setdefault(os.path.normpath(path), []).append((ln, col))
    return errs


def code_mask(s):
    """True where char is real code (outside strings/comments)."""
    mask = [True] * len(s)
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        two = s[i:i+2]
        if two == '//':
            while i < n and s[i] != '\n':
                mask[i] = False; i += 1
            continue
        if two == '/*':
            mask[i] = mask[i+1] = False; i += 2
            while i < n and s[i:i+2] != '*/':
                mask[i] = False; i += 1
            if i < n:
                mask[i] = mask[i+1] = False; i += 2
            continue
        if c in ('"', "'"):
            raw = i > 0 and s[i-1] == 'r'
            triple = s[i:i+3] in ('"""', "'''")
            q = s[i:i+3] if triple else c
            mask[i] = False
            i += len(q)
            while i < n:
                if not raw and s[i] == '\\':
                    mask[i] = False; mask[i+1] = False; i += 2; continue
                if s[i:i+len(q)] == q:
                    for k in range(len(q)):
                        mask[i+k] = False
                    i += len(q)
                    break
                mask[i] = False; i += 1
            continue
        i += 1
    return mask


def line_col_to_off(s, line, col):
    off = 0
    cur = 1
    for ch in s:
        if cur == line:
            return off + (col - 1)
        if ch == '\n':
            cur += 1
        off += 1
    return min(off + col - 1, len(s) - 1)


def governed_ranges(s, mask):
    """For every code `const` keyword, return (kw_start, kw_end, gov_end)."""
    opens, closes = set('([{'), set(')]}')
    out = []
    for m in re.finditer(r'\bconst\b', s):
        k = m.start()
        if not mask[k]:
            continue
        # find first opening bracket after the keyword (skip type/generics)
        j = m.end()
        # stop if we hit a statement end or '=' with no bracket (declaration) -
        # those were handled manually; skip to be safe.
        op = -1
        decl = False
        while j < len(s):
            if mask[j]:
                ch = s[j]
                if ch in opens:
                    op = j; break
                if ch == ';':
                    break
                if ch == '=' and s[j:j+2] != '==':
                    decl = True; break
            j += 1
        if op < 0 or decl:
            continue
        depth = 0
        e = op
        while e < len(s):
            if mask[e]:
                ch = s[e]
                if ch in opens:
                    depth += 1
                elif ch in closes:
                    depth -= 1
                    if depth == 0:
                        break
            e += 1
        out.append((k, m.end(), e))
    return out


def fix_file(path, positions):
    with open(path, 'r', encoding='utf-8') as f:
        s = f.read()
    mask = code_mask(s)
    ranges = governed_ranges(s, mask)
    offs = {line_col_to_off(s, ln, col) for ln, col in positions}
    to_remove = set()
    for (k, kend, gov) in ranges:
        for o in offs:
            if k <= o <= gov:
                to_remove.add((k, kend))
                break
    if not to_remove:
        return 0
    # delete 'const' + following whitespace, from the back
    for (k, kend) in sorted(to_remove, reverse=True):
        e = kend
        while e < len(s) and s[e] in ' \t':
            e += 1
        s = s[:k] + s[e:]
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(s)
    return len(to_remove)


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else 'apps/mobile/lib'
    total = 0
    for _ in range(8):
        errs = analyze(target)
        if not errs:
            break
        round_fixes = 0
        for path, positions in errs.items():
            round_fixes += fix_file(path, positions)
        print(f'round: fixed {round_fixes} const sites across {len(errs)} files')
        total += round_fixes
        if round_fixes == 0:
            break
    print(f'done: removed {total} const keywords')


if __name__ == '__main__':
    main()
