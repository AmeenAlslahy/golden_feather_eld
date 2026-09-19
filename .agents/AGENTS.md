## قاعدة إلزامية — قبل أي commit

1. flutter analyze  → يجب 0 errors، 0 warnings جديدة
2. flutter test     → كل الاختبارات تمر
3. bash scripts/check_architecture.sh

**لا commit بدون هذه الثلاثة.**
