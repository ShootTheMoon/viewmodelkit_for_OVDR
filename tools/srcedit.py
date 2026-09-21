# -*- coding: utf-8 -*-
# .ovdrjm(UTF-8 변환본) 안의 스크립트 Source 를 '진짜 Lua 텍스트' 로 꺼내 고치고 되넣는 도우미.
# 이스케이프된 문자열을 직접 건드리면 백슬래시/줄바꿈에서 사고가 나서 이렇게 한다.
import json

def _find_source_span(s, name):
    key = '"Name": "%s",' % name
    i = s.find(key)
    if i < 0:
        raise SystemExit("[FAIL] 인스턴스 %s 를 못 찾음" % name)
    if s.find(key, i + 1) >= 0:
        raise SystemExit("[FAIL] 인스턴스 %s 가 여러 개" % name)
    j = s.find('"Source": "', i)
    if j < 0:
        raise SystemExit("[FAIL] %s 의 Source 를 못 찾음" % name)
    j += len('"Source": "')
    k = j
    while True:                       # 이스케이프 안 된 따옴표가 끝
        k = s.find('"', k)
        if k < 0:
            raise SystemExit("[FAIL] %s Source 의 끝을 못 찾음" % name)
        b = 0
        while s[k - 1 - b] == '\\':
            b += 1
        if b % 2 == 0:
            return j, k
        k += 1

def get_source(s, name):
    j, k = _find_source_span(s, name)
    return json.loads('"' + s[j:k] + '"')

def set_source(s, name, lua):
    j, k = _find_source_span(s, name)
    esc = json.dumps(lua, ensure_ascii=False)[1:-1]
    return s[:j] + esc + s[k:]

def cut_block(lua, header, tag):
    """`header` 로 시작하는 테이블 블록 하나를 통째로 잘라낸다. 중괄호 짝을 센다."""
    i = lua.find(header)
    if i < 0:
        raise SystemExit("[FAIL] %s : '%s' 를 못 찾음" % (tag, header.strip()))
    if lua.find(header, i + 1) >= 0:
        raise SystemExit("[FAIL] %s : '%s' 가 여러 개" % (tag, header.strip()))
    d = 0
    p = lua.index('{', i)
    for q in range(p, len(lua)):
        if lua[q] == '{':
            d += 1
        elif lua[q] == '}':
            d -= 1
            if d == 0:
                e = q + 1
                if lua[e:e+1] == ',':
                    e += 1
                if lua[e:e+1] == '\n':
                    e += 1
                return lua[i:e], lua[:i] + lua[e:]
    raise SystemExit("[FAIL] %s : 블록이 안 닫힘" % tag)

def one(lua, frm, to, tag):
    n = lua.count(frm)
    if n != 1:
        raise SystemExit("[FAIL] %s : 앵커 %d 개" % (tag, n))
    print("  [ok] " + tag)
    return lua.replace(frm, to, 1)
