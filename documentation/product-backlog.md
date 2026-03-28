# Producto y backlog

## Vision del producto

Gromy nace para cubrir una necesidad clara: organizar y descubrir torneos deportivos amateur desde una plataforma especializada. La propuesta de valor es centralizar la gestion del torneo, la participacion de usuarios y futuras capacidades sociales, de privacidad y monetizacion.

## Backlog del producto

El plan del proyecto define un backlog amplio de historias de usuario. A partir del PDF se identifican 38 historias iniciales, que pueden agruparse por epicas funcionales.

## Epicas funcionales

### 1. Acceso e identidad

- HU1: Registro de usuario
- HU2: Inicio de sesion
- HU15: Editar perfil de usuario
- HU16: Eliminar cuenta de usuario
- HU17: Ver perfil de otros usuarios
- HU18: Historial de torneos del usuario
- HU27: Configurar privacidad del perfil

### 2. Gestion principal de torneos

- HU3: Crear torneo
- HU4: Ver torneos disponibles
- HU9: Configurar visibilidad del torneo
- HU10: Gestionar administradores del torneo
- HU11: Ver informacion detallada del torneo
- HU12: Gestionar calendario de encuentros
- HU13: Gestionar resultados y clasificacion
- HU22: Ver participantes de un torneo

### 3. Descubrimiento y participacion

- HU5: Sistema de inscripcion en torneos
- HU6: Ver torneos cercanos
- HU8: Filtrar torneos
- HU14: Cancelar inscripcion en torneo
- HU19: Buscar torneos

### 4. Funcionalidad social y equipos

- HU7: Sistema de notificaciones
- HU20: Crear equipo
- HU21: Gestionar miembros del equipo
- HU23: Anadir amigos
- HU24: Eliminar amigos

### 5. Seguridad, confianza y moderacion

- HU25: Bloquear usuarios
- HU26: Reportar usuarios
- HU31: Solicitar verificacion de organizador
- HU32: Pago de verificacion de organizador
- HU36: Invitacion conversacional a torneos privados
- HU37: Reenviar invitaciones permitidas a amigos
- HU38: Gestionar estado y limites de invitaciones

### 6. Monetizacion y negocio

- HU28: Valorar torneos
- HU29: Mostrar valoracion media de torneos
- HU30: Sistema de pagos de la plataforma
- HU33: Crear torneos de pago
- HU34: Pagar inscripcion en torneos de pago
- HU35: Gestion de anuncios y patrocinadores

## MVP definido en el plan

El PDF identifica como MVP el conjunto minimo de historias que permiten validar el flujo principal del producto:

- HU1: Registro de usuario
- HU2: Inicio de sesion
- HU3: Crear torneo
- HU4: Ver torneos disponibles
- HU5: Inscripcion en torneos
- HU11: Ver informacion detallada del torneo
- HU8 y HU19: Busqueda y filtrado
- HU6: Visualizacion de torneos cercanos

## Prioridad y estimacion

Segun el documento de planificacion:

- la prioridad se clasifica en alta, media y baja;
- las historias criticas para el MVP se consideran de prioridad alta;
- la estimacion se realiza con Planning Poker;
- la escala usada es relativa y tiene en cuenta complejidad, tamano y riesgo tecnico.

## Definition of Done funcional

Una historia de usuario se considera completada cuando:

- ha sido implementada;
- cumple todos sus criterios de validacion;
- ha sido probada sin errores;
- esta integrada en la aplicacion.

## Trazabilidad con el estado actual del codigo

### Historias parcialmente cubiertas por el repositorio

- HU1: registro de usuario;
- HU2: inicio de sesion;
- parte del flujo previo de HU3 y HU4 mediante estructura de navegacion y pantalla base;
- soporte inicial de perfil de usuario y autenticacion social.

### Historias pendientes o solo esbozadas

- inscripcion en torneos;
- visibilidad de torneos cercanos;
- buscador y filtros funcionales;
- informacion detallada del torneo;
- calendario, clasificacion y participantes;
- equipos, amigos, privacidad avanzada y monetizacion.

## Recomendacion de gestion del backlog

Para mantener la trazabilidad entre Scrum y codigo, se recomienda:

1. asignar cada historia a una epic y a un modulo tecnico del repositorio;
2. definir criterios de aceptacion ejecutables o verificables mediante test;
3. enlazar commits o pull requests a historias concretas;
4. mantener una matriz simple de estado: `pendiente`, `en curso`, `hecha`, `validada`;
5. revisar el backlog al cierre de cada sprint con evidencia funcional y tecnica.
