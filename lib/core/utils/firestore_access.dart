import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Guarda sin esperar al servidor.
///
/// Firestore escribe en su caché **en disco** antes de devolver, y el `Future`
/// de `set()`/`add()`/`update()` solo se resuelve cuando el servidor confirma.
/// Esperarlo deja al usuario mirando un spinner por algo que ya está guardado:
/// con mala conexión el diario tardaba una eternidad, y encadenando dos o tres
/// escrituras, más. La escritura queda encolada, **sobrevive a cerrar la app**
/// y se sincroniza sola en cuanto hay red.
///
/// **No hagas `await` de una escritura de Firestore en un camino que bloquee
/// la interfaz**: pásala por aquí.
Future<void> queueWrite(Future<void> op, String what) async {
  unawaited(op.catchError(
    (Object e) => debugPrint('⚠️ $what no se pudo sincronizar: $e'),
  ));
}

/// Cuánto se espera al servidor antes de conformarse con lo que ya está
/// guardado en el teléfono.
const _readBudget = Duration(seconds: 2);

/// Lecturas de Firestore con presupuesto de tiempo.
///
/// `get()` pide al servidor y **solo** cae a la caché cuando el SDK se da por
/// vencido. Sin internet suele fallar rápido, pero con señal mala —un dato
/// lento, un wifi que no navega— puede tardar muchísimo, y ahí la app se queda
/// mirando un spinner aunque tenga los datos de la última vez guardados en
/// disco.
///
/// `getFast()` espera [_readBudget] y, si no llegó nada, usa la caché local.
/// Así la app abre igual de rápido con o sin internet. Cuando hay red, el
/// comportamiento es el de siempre: datos frescos del servidor.
///
/// **Usa `getFast()` en toda lectura que retrase algo que el usuario está
/// mirando.** Las agregaciones (`count()`) no tienen equivalente: solo existen
/// en el servidor, así que nunca deben bloquear una pantalla.
extension FastDocumentRead<T extends Object?> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> getFast() async {
    try {
      return await get().timeout(_readBudget);
    } catch (e) {
      debugPrint('📴 Lectura desde la caché local: ${path.split('/').last} ($e)');
      return get(const GetOptions(source: Source.cache));
    }
  }
}

extension FastQueryRead<T extends Object?> on Query<T> {
  Future<QuerySnapshot<T>> getFast() async {
    try {
      return await get().timeout(_readBudget);
    } catch (e) {
      debugPrint('📴 Consulta desde la caché local ($e)');
      return get(const GetOptions(source: Source.cache));
    }
  }
}
