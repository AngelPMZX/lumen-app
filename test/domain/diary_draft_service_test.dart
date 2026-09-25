import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/mood_entry.dart';
import 'package:gimnasio_emocional/domain/services/diary_draft_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El borrador del diario no puede sobrevivir a guardar la página.
///
/// Guardar y borrar el borrador son asíncronos: un borrador que se estaba
/// guardando se escribía **después** de borrarlo al guardar la página, y
/// reaparecía al volver a escribir. Guardarlo entonces creaba una segunda copia
/// de la misma página. Ahora las operaciones van en fila.
void main() {
  const uid = 'u1';
  final draft = DiaryDraft(mood: MoodType.happy, text: 'hola diario');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('borrar gana al guardado que estaba en vuelo', () async {
    final service = DiaryDraftService.instance;
    final saving = service.save(uid, draft); // sin await, como en la pantalla
    await service.clear(uid);
    await saving;
    expect(await service.load(uid), isNull);
  });

  test('leer espera a lo que se esté escribiendo', () async {
    final service = DiaryDraftService.instance;
    await service.save(uid, draft);
    final clearing = service.clear(uid);
    expect(await service.load(uid), isNull);
    await clearing;
  });

  test('un borrador guardado se recupera tal cual', () async {
    final service = DiaryDraftService.instance;
    await service.save(uid, DiaryDraft(
      mood: MoodType.calm,
      text: 'algo escrito',
      gratitude: 'el café',
      showGratitude: true,
    ));
    final loaded = await service.load(uid);
    expect(loaded?.mood, MoodType.calm);
    expect(loaded?.text, 'algo escrito');
    expect(loaded?.gratitude, 'el café');
    expect(loaded?.showGratitude, isTrue);
  });

  test('un borrador vacío no se guarda', () async {
    final service = DiaryDraftService.instance;
    await service.save(uid, draft);
    await service.save(uid, const DiaryDraft());
    expect(await service.load(uid), isNull);
  });

  test('cada cuenta tiene el suyo', () async {
    final service = DiaryDraftService.instance;
    await service.save(uid, draft);
    expect(await service.load('otro'), isNull);
    expect((await service.load(uid))?.text, 'hola diario');
  });
}
