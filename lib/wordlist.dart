import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Offline vocabulary catalogue, decoded from `assets/data/vocab.json`.
///
/// The JSON is produced from the workbook sources by `tool/export_vocab.py`,
/// so the app never needs a network connection.
class Vocab {
  Vocab._();

  static List<Topic> topics = const <Topic>[];

  static Topic byId(String id) {
    for (final Topic t in topics) {
      if (t.id == id) return t;
    }
    throw ArgumentError('Unknown topic $id');
  }

  static Future<void> load() async {
    final String raw =
        await rootBundle.loadString('assets/data/vocab.json');
    topics = await compute(_decodeTopics, raw);
  }
}

List<Topic> _decodeTopics(String raw) {
  final Map<String, dynamic> root = jsonDecode(raw) as Map<String, dynamic>;
  final List<dynamic> list = root['topics'] as List<dynamic>;
  final List<Topic> out = <Topic>[];
  for (final dynamic t in list) {
    final Map<String, dynamic> map = t as Map<String, dynamic>;
    final List<dynamic> items = map['items'] as List<dynamic>;
    final List<VocabItem> vocab = <VocabItem>[];
    for (final dynamic it in items) {
      final Map<String, dynamic> m = it as Map<String, dynamic>;
      vocab.add(VocabItem(
        term: (m['term'] as String?) ?? '',
        en: (m['en'] as String?) ?? '',
        bn: (m['bn'] as String?) ?? '',
        syn: (m['syn'] as String?) ?? '',
        ant: (m['ant'] as String?) ?? '',
        ex: (m['ex'] as String?) ?? '',
        pos: (m['pos'] as String?) ?? '',
        theme: (m['theme'] as String?) ?? '',
        bank: (m['bank'] as String?) ?? '',
      ));
    }
    out.add(Topic(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: (map['subtitle'] as String?) ?? '',
      items: vocab,
    ));
  }
  return out;
}

/// Words per day for every topic (requirement: at least 20 per day).
const int wordsPerDay = 20;

/// One vocabulary entry. `en`/`bn`/`syn`/`ant`/`ex` etc. may be empty for
/// topics that do not provide that column.
class VocabItem {
  const VocabItem({
    required this.term,
    required this.en,
    required this.bn,
    required this.syn,
    required this.ant,
    required this.ex,
    required this.pos,
    required this.theme,
    required this.bank,
  });

  final String term; // headword / idiom / substitution word
  final String en; // English meaning / definition
  final String bn; // Bengali meaning / definition
  final String syn; // raw synonyms string
  final String ant; // raw antonyms string
  final String ex; // example sentence
  final String pos; // part of speech
  final String theme; // previous-year vocab theme
  final String bank; // previous-year exam bank reference

  bool get hasEn => en.trim().isNotEmpty;
  bool get hasBn => bn.trim().isNotEmpty;
  bool get hasSyn => syn.trim().isNotEmpty;
  bool get hasAnt => ant.trim().isNotEmpty;
  bool get hasEx => ex.trim().isNotEmpty;

  /// True when the example sentence actually contains the term, which is the
  /// precondition for a "fill in the gap" question.
  bool get gapUsable =>
      hasEx && term.trim().isNotEmpty && ex.toLowerCase().contains(term.toLowerCase());

  /// Example sentence with the term blanked out (for fill-in-the-gap).
  String get gapSentence {
    final String lower = term.toLowerCase();
    final String upper = term.toUpperCase();
    final String title = term.isEmpty
        ? term
        : '${term[0].toUpperCase()}${term.substring(1).toLowerCase()}';
    String s = ex;
    s = s.replaceAll(upper, '______');
    s = s.replaceAll(lower, '______');
    s = s.replaceAll(title, '______');
    return s;
  }

  List<String> get synonyms => _splitList(syn);

  List<String> get antonyms => _splitList(ant);

  static List<String> _splitList(String raw) {
    final List<String> out = <String>[];
    for (final String part in raw.split(RegExp(r'[,;/]'))) {
      final String v = part.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return out;
  }
}

/// A topic (Word Smart, GRE 333, …) plus its day partition.
class Topic {
  Topic({required this.id, required this.title, required this.subtitle, required this.items});

  final String id;
  final String title;
  final String subtitle;
  final List<VocabItem> items;

  int get totalDays => (items.length + wordsPerDay - 1) ~/ wordsPerDay;

  int dayOfItem(int index) => index ~/ wordsPerDay;

  List<int> itemIndexesOfDay(int day) {
    // day is 1-based.
    final int start = (day - 1) * wordsPerDay;
    final int end = start + wordsPerDay;
    final List<int> out = <int>[];
    for (int i = start; i < end && i < items.length; i++) {
      out.add(i);
    }
    return out;
  }

  List<VocabItem> dayItems(int day) {
    final List<VocabItem> out = <VocabItem>[];
    for (final int i in itemIndexesOfDay(day)) {
      out.add(items[i]);
    }
    return out;
  }
}
