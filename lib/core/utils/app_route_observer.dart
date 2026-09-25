import 'package:flutter/material.dart';

/// Observador del navegador raíz: avisa a una pantalla cuando vuelve a estar
/// al frente (`RouteAware.didPopNext`).
///
/// Lo usa `MainShell` para no abrir celebraciones encima de otra pantalla:
/// un diálogo que aparece sobre un flujo que ya está a medias (guardar una
/// página del diario, p. ej.) se queda enredado con él, porque `Navigator.pop`
/// cierra siempre la ruta de arriba y no la propia.
final appRouteObserver = RouteObserver<ModalRoute<dynamic>>();
