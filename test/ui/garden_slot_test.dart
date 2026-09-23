import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/garden_item.dart';
import 'package:gimnasio_emocional/data/models/garden_state.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/garden/garden_defs.dart';
import 'package:gimnasio_emocional/ui/screens/garden/widgets/garden_common.dart';
import 'package:gimnasio_emocional/ui/screens/garden/widgets/garden_plant_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que una planta dibuja se queda dentro de su hueco.
///
/// La píldora de "cuánto falta" colgaba por debajo del cuadro del hueco, y
/// donde dos huecos quedan cerca —la montaña— caía encima de la planta de
/// abajo. Ahora se apoya en la tierra de su propia planta.
const _size = 140.0;

void main() {
  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await SoundService.instance.setEffectsEnabled(false);
  });

  /// Una planta a medio crecer (con píldora, que solo sale si no es adulta).
  (GardenItem, PlantedItem) growing() {
    final item = GardenCatalog.allPlants.firstWhere((p) => p.stageThresholds != null);
    return (
      item,
      PlantedItem(
        instanceId: 'x',
        itemId: item.id,
        plantedAt: DateTime.now().subtract(item.stageThresholds![1] + const Duration(minutes: 1)),
        gardenId: 'meadow',
        slotIndex: 0,
      ),
    );
  }

  testWidgets('la píldora de tiempo no se sale del hueco', (tester) async {
    final (item, planted) = growing();
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        // Sin bucles de animación: si no, `pumpAndSettle` no termina nunca y
        // la entrada del hueco falsearía la medida.
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: _size,
              height: _size,
              child: PlantSlotView(
                planted: planted,
                item: item,
                size: _size,
                mode: SlotMode.normal,
                selected: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final slot = tester.getRect(find.byType(PlantSlotView));
    final pill = tester.getRect(find.byType(GlassPanel));

    // Solo se mira el alto: sin traducciones el texto es la clave cruda
    // (`garden.timeShort`) y la píldora sale mucho más ancha que en la app.
    expect(
      pill.bottom,
      lessThanOrEqualTo(slot.bottom + 0.5),
      reason: 'la píldora vuelve a colgar por debajo del hueco',
    );
    expect(pill.top, greaterThanOrEqualTo(slot.top - 0.5));

    // Y se apoya en la misma línea de tierra que la planta.
    expect(
      pill.bottom - slot.top,
      moreOrLessEquals(PlantGround.line * _size, epsilon: 1),
    );
  });
}
