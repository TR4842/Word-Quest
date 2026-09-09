#!/usr/bin/env python3
"""
Word Quest – vocabulary data exporter.

Reads the source XLSX workbooks at the repository root and writes a single,
compact offline JSON bundle consumed by the Flutter app:
    assets/data/vocab.json

Run from the repository root:
    python3 tool/export_vocab.py

The workbook files remain the source of truth, so the app never needs the
network at runtime. Topic ids referenced here must match lib/wordlist.dart.
"""
import json
import os
import re
import sys

try:
    import openpyxl
except ImportError:
    sys.exit("openpyxl is required:  pip install openpyxl")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "data", "vocab.json")


def clean(v):
    if v is None:
        return ""
    s = str(v).strip()
    return re.sub(r"\s+", " ", s)


def col(header, wanted, row, default=""):
    for i, h in enumerate(header):
        if str(h).strip().lower() == wanted.lower():
            v = clean(row[i]) if i < len(row) else ""
            return v
    return default


def load_rows(fname):
    wb = openpyxl.load_workbook(os.path.join(ROOT, fname), read_only=True)
    ws = wb.worksheets[0]
    it = ws.iter_rows(values_only=True)
    header = next(it)
    rows = []
    for r in it:
        if any(c is not None and str(c).strip() for c in r):
            rows.append(r)
    wb.close()
    return header, rows


def build():
    topics = []

    def topic(tid, title, subtitle):
        t = {"id": tid, "title": title, "subtitle": subtitle, "items": []}
        topics.append(t)
        return t

    # 1) Word Smart 1  (word, POS, Bengali meaning, synonyms, antonyms, example)
    t = topic("wordSmart", "Word Smart", "Word Smart 1 · all vocabularies")
    header, rows = load_rows("Word_Smart_1_All_Vocabularies.xlsx")
    for r in rows:
        t["items"].append(
            {
                "term": col(header, "Word", r),
                "en": "",
                "bn": col(header, "Bengali Meaning", r),
                "syn": col(header, "Synonyms", r),
                "ant": col(header, "Antonyms", r),
                "ex": col(header, "Example Sentence", r),
                "pos": col(header, "Part of Speech", r),
                "theme": "",
                "bank": "",
            }
        )

    # 2) GRE 333 high-frequency words (word, Bengali meaning, synonyms, antonyms)
    t = topic("gre333", "GRE 333", "GRE 333 high-frequency vocabulary")
    header, rows = load_rows("GRE_333_HF_Vocab.xlsx")
    for r in rows:
        t["items"].append(
            {
                "term": col(header, "Word", r),
                "en": "",
                "bn": col(header, "Meaning", r),
                "syn": col(header, "Synonyms", r),
                "ant": col(header, "Antonyms", r),
                "ex": "",
                "pos": "",
                "theme": "",
                "bank": "",
            }
        )

    # 3) Important previous-year bank vocabulary (theme, exam, word, meaning,
    #    synonyms, antonyms)
    t = topic("previousYear", "Previous Bank Vocab", "Important previous-year vocab")
    header, rows = load_rows("Previous Year Vocab.xlsx")
    for r in rows:
        t["items"].append(
            {
                "term": col(header, "English Word", r),
                "en": col(header, "English Meaning", r),
                "bn": "",
                "syn": col(header, "Synonyms", r),
                "ant": col(header, "Antonyms", r),
                "ex": "",
                "pos": "",
                "theme": col(header, "Theme", r),
                "bank": col(header, "Previous years", r),
            }
        )

    # 4) One word substitutions (word, English definition, Bengali meaning)
    t = topic("oneWord", "One Word Substitution", "One word for many words")
    header, rows = load_rows("One_Word_Substitutions.xlsx")
    for r in rows:
        t["items"].append(
            {
                "term": col(header, "Word", r),
                "en": col(header, "English Definition", r),
                "bn": col(header, "Bangla Meaning", r),
                "syn": "",
                "ant": "",
                "ex": "",
                "pos": "",
                "theme": "",
                "bank": "",
            }
        )

    # 5) Idioms & phrases (idiom, English meaning, Bengali definition)
    t = topic("idioms", "Idioms & Phrases", "Idioms and phrases with meaning")
    header, rows = load_rows("Idioms & Phrases.xlsx")
    for r in rows:
        t["items"].append(
            {
                "term": col(header, "Idiom", r),
                "en": col(header, "English Meaning", r),
                "bn": col(header, "Bangla Definition", r),
                "syn": "",
                "ant": "",
                "ex": "",
                "pos": "",
                "theme": "",
                "bank": "",
            }
        )

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"topics": topics}, f, ensure_ascii=False, separators=(",", ":"))

    print(f"wrote {OUT}")
    for t in topics:
        n = len(t["items"])
        # basic sanity checks
        empty_term = sum(1 for i in t["items"] if not i["term"])
        print(
            f"  {t['id']:>13}  {n:5d} items   empty-term:{empty_term}  "
            f"days@20:{(n + 19) // 20}"
        )


if __name__ == "__main__":
    build()
