import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'database_helper.dart';

class WordBookPage extends StatefulWidget {
  const WordBookPage({super.key});

  @override
  State<WordBookPage> createState() => _WordBookPageState();
}

class _WordBookPageState extends State<WordBookPage> {
  FlutterTts flutterTts = FlutterTts();

  final _db = DatabaseHelper();
  List<Map<dynamic, dynamic>> _words = [];
  String _reciteType = 'today';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final db = await _db.database;

    final day = int.parse(await _db.getConfig('day'));

    List<Map<dynamic, dynamic>> result = [];
    if (_reciteType == 'today') {
      result = await db.rawQuery('''
        SELECT w.*
        FROM recite_word
        LEFT JOIN wordlists w ON recite_word.word = w.word
        WHERE recite_type = 'recite' AND (day = ? OR day = ? OR day = ? OR day = ? OR day = ?)
        ORDER BY w.id DESC
      ''', [day, day - 1, day - 3, day - 6, day - 14]);
    } else {
      result = await db.rawQuery('''
        SELECT w.*
        FROM recite_word
        LEFT JOIN wordlists w ON recite_word.word = w.word
        WHERE recite_type = ?
        ORDER BY w.id DESC
      ''', [_reciteType]);
    }

    setState(() {
      _words = result.toList().map((e) => Map.from(e)).toList();
    });
  }

  void _changeShowReciteType(String type) {
    _reciteType = type;
    // ListView回到顶部
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _loadWords();
  }

  Future<void> _changeReciteType(String word, String type) async {
    // 更新数据库
    await _db.updateReciteWord(word, type);
    // 更新列表
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        title: const Icon(Icons.menu_book_outlined, size: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _words.length,
        itemBuilder: (context, index) { 
          Map<dynamic, dynamic> word = _words[index];
          if (word['show'] == null) {
            word['show'] = false;
          }

          List<String> _definitions = [];
          List<String> _examples = [];
          if (word['noun']              != '') _definitions.add('noun: ${word['noun']}');
          if (word['verb']              != '') _definitions.add('verb: ${word['verb']}');
          if (word['transitive_verb']   != '') _definitions.add('transitive_verb: ${word['transitive_verb']}');
          if (word['intransitive_verb'] != '') _definitions.add('intransitive_verb: ${word['intransitive_verb']}');
          if (word['auxiliary_verb']    != '') _definitions.add('auxiliary_verb: ${word['auxiliary_verb']}');
          if (word['adjective']         != '') _definitions.add('adjective: ${word['adjective']}');
          if (word['adverb']            != '') _definitions.add('adverb: ${word['adverb']}');
          if (word['preposition']       != '') _definitions.add('preposition: ${word['preposition']}');
          if (word['interjection']      != '') _definitions.add('interjection: ${word['interjection']}');
          if (word['pronoun']           != '') _definitions.add('pronoun: ${word['pronoun']}');
          if (word['conjunction']       != '') _definitions.add('conjunction: ${word['conjunction']}');
          if (word['abbreviation']      != '') _definitions.add('abbreviation: ${word['abbreviation']}');
          if (word['numeral']           != '') _definitions.add('numeral: ${word['numeral']}');
          if (word['remake']            != '') _definitions.add('remake: ${word['remake']}');

          if (word['example1'] != '') _examples.add(word['example1']);
          if (word['example2'] != '') _examples.add(word['example2']);
          if (word['example3'] != '') _examples.add(word['example3']);
          
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：单词及其信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {setState(() {word['show'] = !word['show'];});},
                          child: Text(
                            word['word'] as String,
                            style: textTheme.headlineSmall?.copyWith(height: 1.0),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              word['symbols'] as String,
                              style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, height: 1.0),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_outlined, size: 24),
                              color: colorScheme.primary,
                              tooltip: '朗读',
                              padding: EdgeInsets.zero,
                              onPressed: () { flutterTts.speak(word['word'] as String); },
                            ),
                          ],
                        ),
                        if (word['show'])
                          const SizedBox(height: 16),
                        if (word['show']) 
                        ..._examples.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• $e'),
                            )),
                        if (word['show']) 
                          const SizedBox(height: 12),
                        if (word['show']) 
                          ..._definitions.map((d) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('- $d'),
                              )),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton.outlined(
                        visualDensity: VisualDensity.comfortable,
                        onPressed: () {_changeReciteType(word['word'], 'simple');},
                        icon: const Icon(Icons.light_mode_outlined, size: 16),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      IconButton.outlined(
                        visualDensity: VisualDensity.comfortable,
                        onPressed: () {_changeReciteType(word['word'], 'familiar');},
                        icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      IconButton.outlined(
                        visualDensity: VisualDensity.comfortable,
                        onPressed: () {_changeReciteType(word['word'], 'recite');},
                        icon: const Icon(Icons.check_outlined, size: 16),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //功能区
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 复习模式
                  IconButton.outlined(
                    onPressed: () {_changeShowReciteType('today');},
                    icon: const Icon(Icons.book),
                  ),
                  IconButton.outlined(
                    onPressed: () {_changeShowReciteType('simple');},
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  IconButton.outlined(
                    onPressed: () {_changeShowReciteType('familiar');},
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                  ),
                  IconButton.outlined(
                    onPressed: () {_changeShowReciteType('recite');},
                    icon: const Icon(Icons.check_outlined),
                  ),
                ],
              ),
            ),
          ],
        )
      ),
    );
  }
}