# Plan Scrum del proyecto

## Marco de trabajo

El proyecto se ha planificado siguiendo Scrum como metodologia agil de referencia. El objetivo es entregar valor incremental mediante iteraciones cortas, con revisiones frecuentes y capacidad de adaptar el alcance a medida que se aprende del producto.

## Objetivos de Scrum en este proyecto

- reducir incertidumbre tecnica en un producto nuevo;
- entregar incrementos funcionales y demostrables;
- priorizar el backlog en funcion del MVP;
- coordinar el trabajo de un equipo academico con tiempos y capacidad limitados;
- mantener trazabilidad entre historias, sprints, demos y entregables.

## Calendario general

### Fase de planificacion

- Periodo: 5 de marzo a 23 de abril
- Objetivo: ideacion, investigacion tecnologica y elaboracion del plan de trabajo

### Sprint 0

- Periodo: 23 de marzo a 10 de abril
- Capacidad estimada: 84 horas
- Objetivo: preparar la base tecnica y entregar un primer core funcional

### Sprint 1

- Periodo: 13 de abril a 8 de mayo
- Capacidad estimada: 114 horas
- Objetivo: completar interaccion principal alrededor de torneos e inscripciones

### Sprint 2

- Periodo: 11 de mayo a 22 de mayo
- Capacidad estimada: 82 horas
- Objetivo: completar funcionalidades diferenciales del MVP y cerrar la demo final

## Alcance por sprint

### Sprint 0

Tareas previstas en el plan:

- configuracion del entorno y del proyecto base en Flutter;
- mockups y templates en Figma;
- integracion con Firebase y base de datos;
- desarrollo de registro, login y autenticacion;
- base para creacion y visualizacion de torneos.

Historias seleccionadas para este sprint:

- HU1: Registro de usuario
- HU2: Inicio de sesion
- HU3: Crear torneo
- HU4: Ver torneos disponibles

Total estimado:

- 21 puntos de historia

### Sprint 1

Tareas previstas en el plan:

- sistema de inscripcion en torneos;
- visualizacion de participantes;
- buscador de torneos;
- cancelacion de inscripcion.

### Sprint 2

Tareas previstas en el plan:

- gestion de torneos por administradores;
- geolocalizacion y filtrado por proximidad;
- privacidad de torneos e invitaciones;
- privacidad del perfil del usuario.

## Capacidad y velocidad

### Capacidad del Sprint 0

El documento calcula la capacidad del Sprint 0 del siguiente modo:

- equipo de 5 integrantes;
- dedicacion semanal fuera de clase: 22 horas;
- dedicacion semanal en clase: 20 horas;
- total semanal: 42 horas;
- duracion del sprint: 2 semanas;
- capacidad total: 84 horas.

### Velocidad estimada

La velocidad inicial se estima en:

- 20 puntos por sprint

El propio plan deja claro que esta velocidad debe ajustarse en sprints posteriores con datos empiricos reales.

## Priorizacion del backlog

Los criterios de priorizacion definidos en el plan son:

- valor para el usuario final;
- dependencias tecnicas;
- impacto sobre el MVP;
- complejidad tecnica y riesgo.

Clasificacion utilizada:

- alta: imprescindible para el MVP;
- media: mejora funcional relevante;
- baja: funcionalidad futura o no critica.

## Metodo de estimacion

La estimacion se realiza mediante Planning Poker usando una escala relativa, lo que permite comparar esfuerzo, complejidad y riesgo entre historias sin forzar una equivalencia directa con horas.

## Eventos Scrum recomendados

Aunque el PDF se centra sobre todo en backlog y planificacion, para una aplicacion practica del marco Scrum se recomienda institucionalizar estos eventos:

### Sprint Planning

- seleccionar historias segun prioridad y capacidad real;
- definir objetivo del sprint;
- descomponer historias en tareas tecnicas.

### Daily Scrum

- sincronizacion breve del equipo;
- visibilidad de bloqueos;
- ajuste de tareas dentro del sprint.

### Sprint Review

- demostracion funcional al cierre de cada sprint;
- validacion del incremento con respecto al objetivo;
- recogida de feedback para reordenar backlog.

### Sprint Retrospective

- identificar que funciono bien;
- detectar fricciones tecnicas u organizativas;
- acordar mejoras concretas para el sprint siguiente.

## Definition of Done

Una historia se considera terminada cuando:

- ha sido implementada;
- cumple todos los criterios de validacion;
- ha sido probada sin errores;
- esta integrada en la aplicacion.

## Relacion con el repositorio

El repositorio actual muestra una buena alineacion con el Sprint 0:

- base de proyecto Flutter configurada;
- autenticacion con Firebase disponible;
- estructura modular inicial creada;
- navegacion principal y pantallas base presentes;
- documentacion tecnica inicial y pruebas automatizadas ya introducidas.

La siguiente mejora natural es convertir el backlog planificado en entregables tecnicos trazables por sprint, enlazando cada historia a:

- modulo afectado;
- tareas tecnicas;
- criterios de aceptacion verificables;
- pruebas asociadas;
- evidencia para la demo del sprint.
