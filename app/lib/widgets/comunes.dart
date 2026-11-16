import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// Etiqueta de tipo de torneo (Federación, Club, Circuito, Nacional).
class TipoBadge extends StatelessWidget {
  const TipoBadge(this.tipo, {super.key, this.enVerde = false});
  final String tipo;
  final bool enVerde;

  @override
  Widget build(BuildContext context) {
    final color = FlogColors.tipo(tipo);
    return Etiqueta(
      tipo == 'Nacional en la CV' ? 'Nacional' : tipo,
      color: enVerde ? Colors.white : color,
      fondo: enVerde ? Colors.white.withValues(alpha: 0.16) : color.withValues(alpha: context.esOscuro ? 0.22 : 0.12),
    );
  }
}

class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, required this.color, required this.fondo, this.icono});
  final String texto;
  final Color color;
  final Color fondo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono case final icono?) ...[Icon(icono, size: 13, color: color), const SizedBox(width: 4)],
          Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

class EtiquetaNuevo extends StatelessWidget {
  const EtiquetaNuevo({super.key});
  @override
  Widget build(BuildContext context) =>
      const Etiqueta('Nuevo', color: FlogColors.verde900, fondo: FlogColors.lima, icono: Icons.auto_awesome);
}

class EtiquetaCambio extends StatelessWidget {
  const EtiquetaCambio(this.texto, {super.key});
  final String texto;
  @override
  Widget build(BuildContext context) => Etiqueta(
        texto,
        color: FlogColors.aviso,
        fondo: FlogColors.aviso.withValues(alpha: context.esOscuro ? 0.22 : 0.12),
        icono: Icons.info_outline,
      );
}

class EtiquetaInscripcion extends StatelessWidget {
  const EtiquetaInscripcion({super.key});
  @override
  Widget build(BuildContext context) => Etiqueta(
        'Inscripción abierta',
        color: FlogColors.verde700,
        fondo: FlogColors.verde500.withValues(alpha: context.esOscuro ? 0.25 : 0.12),
        icono: Icons.how_to_reg_outlined,
      );
}

/// Cuadro con el día grande, como en las apps de eventos.
class CajaFecha extends StatelessWidget {
  const CajaFecha({super.key, required this.fecha, this.fin, this.claro = false, this.tamano = 64});
  final DateTime fecha;
  final DateTime? fin;
  final bool claro;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fg = claro ? Colors.white : FlogColors.verde900;
    final bg = claro ? Colors.white.withValues(alpha: 0.14) : FlogColors.lima.withValues(alpha: context.esOscuro ? 0.18 : 0.45);
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final multi = fin != null && !_mismoDia(fin!, fecha);
    return Container(
      width: tamano,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dias[fecha.weekday - 1].toUpperCase(),
              style: t.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8), fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          Text(
            multi ? '${fecha.day}–${fin!.day}' : '${fecha.day}',
            style: t.headlineSmall?.copyWith(color: fg, fontSize: multi ? 18 : 26, height: 1.1),
          ),
          Text(meses[fecha.month - 1], style: t.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Cifra grande con título pequeño, para la cabecera.
class Cifra extends StatelessWidget {
  const Cifra({super.key, required this.valor, required this.titulo});
  final String valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: t.headlineSmall?.copyWith(color: Colors.white, height: 1.1)),
            ),
            const SizedBox(height: 2),
            Text(titulo, style: t.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.titulo, this.texto, this.icono = Icons.golf_course_outlined, this.accion});
  final String titulo;
  final String? texto;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Icon(icono, size: 52, color: context.flog.textoSuave),
          const SizedBox(height: 14),
          Text(titulo, style: t.titleLarge, textAlign: TextAlign.center),
          if (texto case final texto?) ...[
            const SizedBox(height: 6),
            Text(texto, style: t.bodyMedium?.copyWith(color: context.flog.textoSuave), textAlign: TextAlign.center),
          ],
          if (accion case final accion?) ...[const SizedBox(height: 16), accion],
        ],
      ),
    );
  }
}

/// Franja de aviso discreta ("Sin conexión").
class Franja extends StatelessWidget {
  const Franja({super.key, required this.texto, this.icono = Icons.cloud_off_outlined});
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FlogColors.dorado.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, size: 16, color: FlogColors.dorado),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.labelMedium)),
        ],
      ),
    );
  }
}

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.derecha});
  final String texto;
  final Widget? derecha;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
          ?derecha,
        ],
      ),
    );
  }
}
