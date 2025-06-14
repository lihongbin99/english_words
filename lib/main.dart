import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'word_book.dart';

void main() => runApp(const WordApp());

class WordApp extends StatelessWidget {
  const WordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'Word Learning',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const WordLearningPage(),
    );
  }
}

class WordLearningPage extends StatefulWidget {
  const WordLearningPage({super.key});

  @override
  State<WordLearningPage> createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage> {
  int _day = 0;
  String _reciteType = "recite";
  // 单词总数
  int _total = 0;
  // 已学简单单词数
  int _simple = 0;
  // 已学熟悉单词数
  int _familiar = 0;
  // 已学背诵单词数
  int _recite = 0;
  int _totalLearn = 0;
  // 已复习单词数
  int _reviewedWords = 0;
  // 待复习单词数
  int _wordsToReview = 0;
  // 今天学习的单词数量
  int _todayLearn = 0;
  // 展示单词
  bool _show = false;
  // 当前单词
  String _word = '';
  // 音标
  String _phonetic = '';
  // 例句
  List<String> _examples = [];
  // 释义
  List<String> _definitions = [];

  // 复习单词
  List<Map<String, dynamic>?> _reviewWords = [];
  Set<String> _reviewSet = Set<String>();

  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final reciteType = await _db.getConfig('recite_type');

    final day = await _db.getConfig('day');
    _day = int.parse(day);

    // 获取单词总数
    final total = await _db.getTotalWords();
    // 获取已学单词数
    final simple = await _db.getRecitedWordsByType('simple');
    // 获取已学单词数
    final familiar = await _db.getRecitedWordsByType('familiar');
    // 获取已学背诵单词数
    final recite = await _db.getRecitedWordsByType('recite');
    // 获取今天学习的单词数量
    final todayLearn = await _db.getRecitedWordsByDay(_day);

    Map<String, dynamic>? word;
    // 复习模式
    if (reciteType == 'review') {
      if (_reviewWords.isEmpty) {
        // 今日复习单词
        List<Map<String, dynamic>> todayReviewWords = await _db.getTodayReviewWords();
        if (todayReviewWords.isNotEmpty) {
          _reviewWords = todayReviewWords.toList();
          _reviewWords.shuffle();
          _reviewedWords = 0;
        }
      }
      if (_reviewWords.isNotEmpty) {
        word = _reviewWords[_reviewedWords];
        _wordsToReview = _reviewWords.length;
      }
    } else {
      // 学习模式
      word = await _db.getFirstUnrecitedWord();
    }

    List<String> definitions = [];
    List<String> examples = [];
    if (word != null) {
      if (word['noun']              != '') definitions.add('noun: ${word['noun']}');
      if (word['verb']              != '') definitions.add('verb: ${word['verb']}');
      if (word['transitive_verb']   != '') definitions.add('transitive_verb: ${word['transitive_verb']}');
      if (word['intransitive_verb'] != '') definitions.add('intransitive_verb: ${word['intransitive_verb']}');
      if (word['auxiliary_verb']    != '') definitions.add('auxiliary_verb: ${word['auxiliary_verb']}');
      if (word['adjective']         != '') definitions.add('adjective: ${word['adjective']}');
      if (word['adverb']            != '') definitions.add('adverb: ${word['adverb']}');
      if (word['preposition']       != '') definitions.add('preposition: ${word['preposition']}');
      if (word['interjection']      != '') definitions.add('interjection: ${word['interjection']}');
      if (word['pronoun']           != '') definitions.add('pronoun: ${word['pronoun']}');
      if (word['conjunction']       != '') definitions.add('conjunction: ${word['conjunction']}');
      if (word['abbreviation']      != '') definitions.add('abbreviation: ${word['abbreviation']}');
      if (word['numeral']           != '') definitions.add('numeral: ${word['numeral']}');
      if (word['remake']            != '') definitions.add('remake: ${word['remake']}');
      if (word['example1_translation']            != '') definitions.add('example: ${word['example1_translation']}');
      if (word['example2_translation']            != '') definitions.add('example: ${word['example2_translation']}');
      if (word['example3_translation']            != '') definitions.add('example: ${word['example3_translation']}');

      if (word['example1'] != '') examples.add(word['example1']);
      if (word['example2'] != '') examples.add(word['example2']);
      if (word['example3'] != '') examples.add(word['example3']);
    }

    setState(() {
      _show = false;
      _reciteType = reciteType;
      // 单词总数
      _total = total;
      // 已学简单单词数
      _simple = simple;
      // 已学熟悉单词数
      _familiar = familiar;
      // 已学背诵单词数
      _recite = recite;
      _totalLearn = simple+familiar+recite;
      _todayLearn = todayLearn;
      // 当前单词
      _word = word?['word'] ?? '';
      // 音标
      _phonetic = word?['symbols'] ?? '';
      // 例句
      _examples = examples;
      // 释义
      _definitions = definitions;
    });
  }

  // 展示单词解释
  Future<void> show() async {
    setState(() {
      _show = !_show;
    });
  }

  // 学习单词
  Future<void> _handleWordRecited(String reciteType) async {
    if (_word != '') {
      // 添加日志
      if (reciteType == 'recite') {
        await _db.addReciteLog(_word, 0);
      } else {
        await _db.addReciteLog(_word, 1);
      }
      
      // 添加已背单词
      await _db.addRecitedWord(_word, reciteType, _day);
      
      // 更新进度条
      if (reciteType == 'recite') {
        // 已复习单词数
        _reviewedWords += 1;
        // 待复习单词数
        _wordsToReview += 1;

        // 添加到复习列表
        await _db.addReviewWord(_word);
      }
      // 更新页面
      _loadStats();
    }
  }

  // 复习单词
  Future<void> _review(int type) async {
    if (_word != '') {
      await _db.addReciteLog(_word, type);
      if (type == 0) {
        // 复习失败
        _reviewSet.remove(_word);
      } else {
        // 复习成功
        if (_reviewSet.contains(_word)) {
          _reviewSet.remove(_word);
          // 删除复习单词
          await _db.deleteReviewWord(_word);
        } else {
          _reviewSet.add(_word);
        }
      }
      // 更新进度
      _reviewedWords += 1;
      if (_reviewedWords >= _reviewWords.length) {
        _reviewWords = [];
        _reviewedWords = 0;
        _wordsToReview = 0;
      }
      _loadStats();
    }
  }

  // 切换复习/学习模式
  Future<void> _handleReciteType(String reciteType) async {
    await _db.setConfig('recite_type', reciteType);
    // 已复习单词数
    _reviewedWords = 0;
    // 待复习单词数
    _wordsToReview = 0;
    _loadStats();
  }

  // 切换到下一天
  Future<void> _nextDay() async {
    _day += 1;
    await _db.setConfig('day', _day.toString());
    _reviewWords = [];
    _reviewedWords = 0;
    _wordsToReview = 0;
    _reviewSet.clear();
    // 添加复习单词
    await _db.addReviewWords(_day);
    _loadStats();
  }

  // 清空复习单词
  Future<void> _flushReviewWords() async {
    _reviewWords = [];
    _reviewedWords = 0;
    _wordsToReview = 0;
    _reviewSet.clear();
    // 添加复习单词
    await _db.addReviewWords(_day);
    // 添加今天的单词
    await _db.addTodayReviewWords(_day);
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // 学习进度
    final learnedProgress = _total == 0 ? 0.0 : (_simple+_familiar+_recite) / _total;

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
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WordBookPage()),
              );
            },
            icon: const Icon(Icons.book),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 学习进度
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_simple / $_familiar / $_recite', style: textTheme.bodyMedium),
                        Text('$_totalLearn / $_total', style: textTheme.bodyMedium),
                        Text('${(learnedProgress * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          if (_simple > 0)
                            Flexible(flex: _simple, child: Container(color: colorScheme.primary.withAlpha(250), height: 12)),
                          if (_familiar > 0)
                            Flexible(flex: _familiar, child: Container(color: colorScheme.primary.withAlpha(200), height: 12)),
                          if (_recite > 0)
                            Flexible(flex: _recite, child: Container(color: colorScheme.primary.withAlpha(150), height: 12)),
                          Flexible(flex: _total-_totalLearn, child: Container(color: colorScheme.primary.withAlpha(50), height: 12,)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 复习进度
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_reviewedWords / $_wordsToReview', style: textTheme.bodyMedium),
                        Text('$_day-$_todayLearn', style: textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Flexible(flex: _wordsToReview == 0 ? 1 : _reviewedWords, child: Container(color: colorScheme.primary.withAlpha(250), height: 12)),
                          Flexible(flex: _wordsToReview-_reviewedWords, child: Container(color: colorScheme.primary.withAlpha(50), height: 12,)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 单词详情
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {show();},
                      child: Text(_word, style: textTheme.headlineMedium),
                    ),
                    Text(_phonetic, style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                    const SizedBox(height: 16),
                    ..._examples.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $e'),
                        )),
                    if (_show) 
                      const SizedBox(height: 12),
                    if (_show) 
                      ..._definitions.map((d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('- $d'),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  if (_reciteType == 'review' && _wordsToReview == 0 && _todayLearn > 0)
                    IconButton.outlined(
                      onPressed: () {_nextDay();},
                      icon: const Icon(Icons.chevron_right_outlined),
                    ),
                  if (_reciteType == 'review' && _wordsToReview == 0)
                    IconButton.outlined(
                      onPressed: () {_flushReviewWords();},
                      icon: const Icon(Icons.refresh),
                    ),
                  if (_reciteType == 'review' && _wordsToReview == 0)
                    IconButton.outlined(
                      onPressed: () {_handleReciteType('recite');},
                      icon: const Icon(Icons.play_arrow_outlined),
                    ),
                  if (_reciteType == 'review' && _wordsToReview > 0)
                    IconButton.outlined(
                      onPressed: () {_review(0);},
                      icon: const Icon(Icons.close_outlined),
                    ),
                  if (_reciteType == 'review' && _wordsToReview > 0)
                    IconButton.outlined(
                      onPressed: () {_review(1);},
                      icon: const Icon(Icons.check_outlined),
                    ),
                  // 学习模式
                  if (_reciteType == 'recite')
                    IconButton.outlined(
                      onPressed: () {_handleReciteType('review');},
                      icon: const Icon(Icons.stop_outlined),
                    ),
                  if (_reciteType == 'recite')
                    IconButton.outlined(
                      onPressed: () {_handleWordRecited('simple');},
                      icon: const Icon(Icons.light_mode_outlined),
                    ),
                  if (_reciteType == 'recite')
                    IconButton.outlined(
                      onPressed: () {_handleWordRecited('familiar');},
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                    ),
                  if (_reciteType == 'recite')
                    IconButton.outlined(
                      onPressed: () {_handleWordRecited('recite');},
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