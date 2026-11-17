import 'package:material_ui/material_ui.dart';

/// Paleta Flog (ver branding/paleta.md).
class FlogColors {
  FlogColors._();

  static const verde900 = Color(0xFF0F3D2E);
  static const verde700 = Color(0xFF1B5E46);
  static const verde500 = Color(0xFF2A7A5C);
  static const lima = Color(0xFFB6E388);
  static const limaOscuro = Color(0xFF7FB64A);
  static const dorado = Color(0xFFC9A227);
  static const azul = Color(0xFF2F6FB0);
  static const ciruela = Color(0xFF7B3B6B);
  static const aviso = Color(0xFFE2572B);

  static const fondoClaro = Color(0xFFF4F6F2);
  static const superficieClara = Color(0xFFFFFFFF);
  static const textoClaro = Color(0xFF121A14);
  static const textoSuaveClaro = Color(0xFF5B6B60);
  static const lineaClara = Color(0xFFDCE3DA);

  static const fondoOscuro = Color(0xFF0B1F17);
  static const superficieOscura = Color(0xFF14291F);
  static const textoOscuro = Color(0xFFEEF3EC);
  static const textoSuaveOscuro = Color(0xFFA7B5AB);
  static const lineaOscura = Color(0xFF24392F);

  /// Color por tipo de torneo.
  static Color tipo(String tipo) {
    switch (tipo) {
      case 'Federación':
        return dorado;
      case 'Nacional en la CV':
        return ciruela;
      case 'Circuito':
        return azul;
      default:
        return verde500;
    }
  }
}

/// Colores de la app que dependen del brillo, accesibles vía `context.flog`.
class FlogTokens extends ThemeExtension<FlogTokens> {
  const FlogTokens({
    required this.fondo,
    required this.superficie,
    required this.texto,
    required this.textoSuave,
    required this.linea,
  });

  final Color fondo;
  final Color superficie;
  final Color texto;
  final Color textoSuave;
  final Color linea;

  static const claro = FlogTokens(
    fondo: FlogColors.fondoClaro,
    superficie: FlogColors.superficieClara,
    texto: FlogColors.textoClaro,
    textoSuave: FlogColors.textoSuaveClaro,
    linea: FlogColors.lineaClara,
  );
  static const oscuro = FlogTokens(
    fondo: FlogColors.fondoOscuro,
    superficie: FlogColors.superficieOscura,
    texto: FlogColors.textoOscuro,
    textoSuave: FlogColors.textoSuaveOscuro,
    linea: FlogColors.lineaOscura,
  );

  @override
  FlogTokens copyWith({Color? fondo, Color? superficie, Color? texto, Color? textoSuave, Color? linea}) =>
      FlogTokens(
        fondo: fondo ?? this.fondo,
        superficie: superficie ?? this.superficie,
        texto: texto ?? this.texto,
        textoSuave: textoSuave ?? this.textoSuave,
        linea: linea ?? this.linea,
      );

  @override
  FlogTokens lerp(FlogTokens? other, double t) {
    if (other == null) return this;
    return FlogTokens(
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      texto: Color.lerp(texto, other.texto, t)!,
      textoSuave: Color.lerp(textoSuave, other.textoSuave, t)!,
      linea: Color.lerp(linea, other.linea, t)!,
    );
  }
}

/// Fraunces (variable, empaquetada en assets/fonts) para títulos; Inter para el cuerpo.
class FlogFonts {
  FlogFonts._();

  static TextStyle titulo({Color? color, double peso = 700, bool suave = true}) => TextStyle(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w700,
        color: color,
        fontVariations: [
          FontVariation('wght', peso),
          const FontVariation('opsz', 72),
          FontVariation('SOFT', suave ? 60 : 0),
          const FontVariation('WONK', 0),
        ],
      );
}

extension FlogContext on BuildContext {
  FlogTokens get flog => Theme.of(this).extension<FlogTokens>()!;
  bool get esOscuro => Theme.of(this).brightness == Brightness.dark;
}

class FlogTheme {
  FlogTheme._();

  static ThemeData _base(Brightness b) {
    final oscuro = b == Brightness.dark;
    final tokens = oscuro ? FlogTokens.oscuro : FlogTokens.claro;
    final scheme = ColorScheme(
      brightness: b,
      primary: oscuro ? FlogColors.lima : FlogColors.verde900,
      onPrimary: oscuro ? FlogColors.verde900 : Colors.white,
      secondary: FlogColors.lima,
      onSecondary: FlogColors.verde900,
      error: FlogColors.aviso,
      onError: Colors.white,
      surface: tokens.superficie,
      onSurface: tokens.texto,
      surfaceContainerHighest: oscuro ? const Color(0xFF1C3328) : const Color(0xFFE9EEE6),
      outline: tokens.linea,
      tertiary: FlogColors.dorado,
      onTertiary: Colors.white,
    );

    final base = (oscuro ? ThemeData.dark() : ThemeData.light()).textTheme;
    final cuerpo = base
        .apply(fontFamily: 'Inter', bodyColor: tokens.texto, displayColor: tokens.texto)
        .copyWith(
          titleMedium: base.titleMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16, color: tokens.texto),
          bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Inter', fontSize: 16, height: 1.45, color: tokens.texto),
          bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Inter', fontSize: 14.5, height: 1.4, color: tokens.texto),
          labelLarge: base.labelLarge?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: tokens.texto),
          labelMedium: base.labelMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w600, letterSpacing: 0.2, color: tokens.texto),
          labelSmall: base.labelSmall?.copyWith(fontFamily: 'Inter', color: tokens.texto),
        );
    final titulos = FlogFonts.titulo(color: tokens.texto);
    final textTheme = cuerpo.copyWith(
      displayLarge: titulos.copyWith(fontSize: 46, height: 1.05, letterSpacing: -1.0),
      displayMedium: titulos.copyWith(fontSize: 36, height: 1.1, letterSpacing: -0.6),
      headlineMedium: titulos.copyWith(fontSize: 28, height: 1.15, letterSpacing: -0.4),
      headlineSmall: titulos.copyWith(fontSize: 24, height: 1.2, letterSpacing: -0.3),
      titleLarge: titulos.copyWith(fontSize: 21, height: 1.25, letterSpacing: -0.2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.fondo,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: FlogColors.verde900,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: titulos.copyWith(fontSize: 22, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: tokens.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.linea),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.superficie,
        selectedColor: FlogColors.verde900,
        side: BorderSide(color: tokens.linea),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: oscuro ? FlogColors.superficieOscura : Colors.white,
        indicatorColor: oscuro ? FlogColors.verde700 : FlogColors.lima.withValues(alpha: 0.55),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? scheme.primary : tokens.textoSuave,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : tokens.textoSuave),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: tokens.linea),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
          foregroundColor: tokens.texto,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tokens.linea)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tokens.linea)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: FlogColors.verde500, width: 1.5)),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textoSuave),
      ),
      dividerTheme: DividerThemeData(color: tokens.linea, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? FlogColors.verde900 : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? FlogColors.lima : null),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static ThemeData get claro => _base(Brightness.light);
  static ThemeData get oscuro => _base(Brightness.dark);
}
