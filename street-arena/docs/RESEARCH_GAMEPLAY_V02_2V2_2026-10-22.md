# MatchMake Street Arena — Investigación técnica y especificación Alpha 0.2 / 2v2

**Fecha de corte:** 2026-10-22 (hora Chile). **Estado:** estudio y propuesta; ninguna mecánica implementada.  
**Base revisada:** rama \`prototype/street-arena-cloud-20261022\`, \`street-arena/game.js\` e \`index.html\` de \`orlandoue/matchmake-app\`.  
**Objetivo:** preservar visual 3D actual y mejorar conducción, primer toque, dribleo, regates, tiros con carga, pases, defensas y 2v2; usuario sin instalaciones locales; nube GitHub+Render.  
**Regla:** NO modificar \`game.js\`, \`index.html\` ni desplegar Alpha 0.2 antes de aprobar el contrato y los tests.

## 1. Hallazgos confirmados en Alpha 0.1

- Render: Three.js; simulación: JS en el mismo bucle, \`dt\` variable \`Math.min((time-lastFrame)/1000,.045)\`.
- Entradas: WASD y flechas como movimiento; espacio chute; Shift sprint; E robar.
- Movimiento: posiciones \`x,z\` sumadas con velocidades inmediatas (7.1/10.1); sin aceleración, desaceleración ni velocidad de giro.
- Balón: estado \`x,z,vx,vz\`; fricción exponencial; sin altura, dueño, estado de recepción ni clasificación de contacto.
- Conducción: \`pd<1.2\` y movimiento -> suma \`32*dt\` a \`vx,vz\`; sin control fino.
- Disparo: distancia menor de 2.0, velocidad exacta 21, dirección del último desplazamiento; mantener botón lo reitera tras cooldown.
- Robo: distancia menor de 2.4, impulso al balón 9.8; no mide orientación, timing o trayectoria adversaria.
- Rival: persigue el balón a velocidad 4.6 y dispara hacia portería contraria, sin rol táctico ni anticipación.
- No hay pases, elevaciones, fintas, barridas, árbitro, porteros, compañeros, balance 2v2, multijugador ni servidor autoritativo.
- La Alpha 0.1 no tiene separación \`simulation / rendering / input / networking\`.
- Goles detectados por \`z\` y anchura de arco; falta cruce del plano con control de la trayectoria.

## 2. Repositorios y documentación inspeccionados

| Prioridad | Proyecto | Licencia / estado visible | Lección para MatchMake |
|---|---|---|---|
| 1 | https://github.com/haeretici/soccer-js | MIT; código y docs de IA/control | Simulación independiente del render, FSM, zonas de apoyo, seguridad del pase, pases al hueco, barridas con recuperación, barridos de parámetros y escenarios headless. Véase \`docs/01_architecture.md\` y \`docs/02_ai_and_match.md\`. 2D isométrico: NO transplantar íntegramente. |
| 1 | https://github.com/markclausing/websoccer | MIT; repositorio pequeño | Simulación determinista pura \`step(state,inputs)\`, 60 Hz, charge shot, pase con asistencia y tiros libres de asistencia, pruebas online; lockstep viable como referencia pero latencia y confianza hacen preferible servidor autoritativo para competitivo. |
| 1 | https://github.com/google-research/football | Apache-2.0 en distribución principal; archivado el 2026-08-19 | Modelo de acciones de fútbol, escenarios de pase, multiagente, entrenamientos y comparación de políticas. Dependencia C++/Python: referencia, NO integración directa al browser. Revisar licencias de assets/dependencias por separado. |
| 2 | https://github.com/rcsoccersim/rcssserver | LGPL-3.0 visible en GitHub | Referencia científica de modelo de comandos patear/tackle, física simplificada y arquitectura server/agents. No idóneo directamente para UX 3D arcade. |
| 1 | https://github.com/dimforge/rapier | Apache-2.0 | Motor WASM de físicas 2D/3D; CCD para balones rápidos, colisiones, determinismo WebAssembly bajo condiciones. Probar solo después de validar un núcleo 2.5D simple. |
| 1 | https://github.com/colyseus/colyseus y https://github.com/colyseus/prediction-playground | Colyseus MIT | Rooms, servidor autoritativo, predicción/reconciliación, snapshots e interpolación. Colyseus 0.18 lanzado en agosto 2026; versión debe fijarse antes de programar. |
| 2 | https://gafferongames.com/post/fix_your_timestep/ y https://new.gafferongames.com/post/snapshot_interpolation/ | Publicaciones técnicas (no código reutilizable asumido) | Separar lógica y render; interpolación; diferencias entre lockstep y servidor con snapshots. |

Verificación de fuentes y detalles: https://github.com/haeretici/soccer-js/blob/master/docs/02_ai_and_match.md ; https://github.com/markclausing/websoccer ; https://github.com/google-research/football/blob/master/README.md ; https://rapier.rs/docs/user_guides/javascript/rigid_body_ccd/ ; https://docs.colyseus.io/netcode ; https://colyseus.io/blog/colyseus-018-is-here/.

## 3. Bibliografía científica principal y alcance

1. Brink et al. (2023), *Measuring skill via player dynamics in football dribbling*, Scientific Reports 13:19004, DOI 10.1038/s41598-023-45914-6, https://pmc.ncbi.nlm.nih.gov/articles/PMC10624867/. Modela atacante y defensor como sistema dinámico acoplado: inspirar anticipación y diferencias de velocidad, no copiar coeficientes reales en arcade.
2. Lees et al. (2010), *The biomechanics of kicking in soccer: a review*, J Sports Sci, DOI 10.1080/02640414.2010.481305, https://pubmed.ncbi.nlm.nih.gov/20509089/. Relación del pie, contacto, lanzamiento y balón: base física conceptual para separar técnica, potencia y dirección.
3. Fajen & Warren (2007), *Behavioral dynamics of intercepting a moving target*, DOI 10.1007/s00221-007-0859-6, https://pubmed.ncbi.nlm.nih.gov/17273872/. Interceptar proyectando posiciones futuras, no perseguir coordenadas instantáneas.
4. Kurach et al. (2020), *Google Research Football: A Novel Reinforcement Learning Environment*, AAAI, DOI 10.1609/aaai.v34i04.5878, https://ojs.aaai.org/index.php/AAAI/article/view/5878. Multiagente, simulación 3D y ejercicios reproducibles.
5. Bush (2013), *The aerodynamics of the beautiful game*, https://dspace.mit.edu/entities/publication/2e973612-e01f-4857-a455-983b1150f82b. Resistencia y efecto Magnus para fase opcional de tiros con curva; no hace falta aerodinámica completa en MVP.
6. Gearing & Bridge (2026), *How do small-sided games play a role in skill acquisition...*, DOI 10.1016/j.footst.2026.100047, https://www.sciencedirect.com/science/article/pii/S3051268926000279. 1v1/2v2/3v3 ofrecen oportunidades relevantes para habilidad/decisión; respalda formato corto.
7. *The Impact of Touch Restrictions in Small-Sided Games on Soccer Players' Passing, Receiving, and Ball-Touch Temporal Intervals* (2025), https://pmc.ncbi.nlm.nih.gov/articles/PMC12360936/. Restricciones a toques afectan frecuencia de pases; utilizable para diseñar escenarios de pruebas y modos alternativos.
8. *Space and Control in Soccer* (2021), https://pmc.ncbi.nlm.nih.gov/articles/PMC8322620/. Control espacial y ventajas de pases: inspirar utilidad de líneas de pase en IA.
9. Holden, Komura, Saito (2017), *Phase-functioned neural networks for character control*, DOI 10.1145/3072959.3073663, https://hub.hku.hk/handle/10722/288880. Animación reactiva avanzada; referencia a futuro, excesiva para primera Alpha 0.2.
10. Beato et al. (2026), *Framework and consensus statement for sided game training in football*, DOI 10.1123/ijspp.2025-0678, https://eprints.gla.ac.uk/386134/. Resalta importancia de número de jugadores, dimensiones y reglas.

Importante: la traducción de resultados de deporte real a parámetros de videojuego es **hipótesis de diseño**, no validación empírica del gameplay MatchMake.

## 4. Contrato de controles propuesto (no implementado)

Flechas ↑ ↓ ← → = **movimiento solamente**. Espacio y Shift = **sin acción**. Letras A/S/D/W/Q/E = **acciones**.  
Controles contextuales:
| Tecla | Con posesión o atacando | Sin posesión o defendiendo |
|---|---|---|
| A | Pase corto dirigido | Entrada de pie / poke tackle |
| S | Tiro: mantener carga, soltar ejecuta | Despeje |
| D | Finta/regate (dirección con flechas; skill contextual) | Barrida direccional |
| W | Pase largo/por alto/al espacio (cargar opcional) | Presión / cierre de línea |
| Q | Control fino, amortiguar recepción / primer toque orientado | Cambiar avatar controlado en 2v2 |
| E | Sprint (mantener) | Sprint / recuperación |

**Nota de UX:** con pase/tiro la última flecha define orientación al soltar; si no hay flecha, mantener orientación previa. Acción en contexto ambiguo debe ser explícita y conservadora; configurar botones más tarde. Teclas A/S/D/W/Q/E no vuelven a mover al avatar.

## 5. Arquitectura de simulación propuesta (reversible)

- Render visual Three.js original: cancha, atletas, branding y cámara sin rediseñar.
- \`GameSimulation.step(inputFrame, dt=1/60)\` independiente de DOM, WebGL, Date, Performance y network. Un estado serializable (al menos x,z,vx,vz y en fase posterior y/vy).
- Datos de entidades: \`Player\` (id, team, pos, velocity, facing, actionState, actionTicks, fatigue/cooldown, controlledBy), \`Ball\` (pos, velocity, possessorId/null, contactState, lastTouchId, timers), \`Match\` (teams, goals, gameTick, phase).
- Render a tasa variable sobre snapshots interpolados. Entrada desacoplada con \`pressed\`/\`held\`/\`released\` almacenados por tick. Un toque fugaz no debe perderse.
- Aleatoriedad de IA con seed, nunca \`Math.random()\` en lógica determinista; coordenadas discretizadas o precisión acordada.
- Para prototipo: plano XZ con dimensiones visuales 3D (2.5D). Balón 2.5D de altura opcional; validar primero ground-pass; altura real si falta robustez / red de gol.
- Física basada en matemática propia, con colisiones barridas (swept) de balón, defensores, postes, paredes. Ensayo A/B contra Rapier 3D: precisión, CCD, costo, compatibilidad en cliente/servidor y reproducibilidad.
- Arquitectura futura de red: sala Colyseus autoritativa en Render Node, estados/entradas; servidor valida cooldown, tiro, posesión y goles; cliente predice solo su avatar, interpola remotos y reconcilia; NO otorgar autoridad de score al cliente. Las salas deben probarse con pérdida, jitter y reconexión.
- No requiere instalar entorno de desarrollo en el computador del usuario. Compilación y pruebas en GitHub Actions / Render; juego en navegador.

## 6. Modelos de control y pelota — hipótesis iniciales sujetas a calibración

### A. Movimiento
En lugar de saltar a velocidad máxima:
\`v_des = speed(mode)*direction\`  
\`v_next = v + clampMagnitude(v_des-v, a_max*dt)\`  
\`pos_next = pos + v_next*dt\`.
Para giros: limitar velocidad angular, usar blending de animación (primero procedural). Dejar velocidad mínima de avance cuando frena, probar respuesta sin sensación viscosa.

### B. Estado físico/control del balón
Estados propuestos:
\`FREE\` (independiente), \`FIRST_TOUCH\` (ventana para recepción), \`CONTROLLED\` (toques), \`RELEASED\` (pase/tiro), \`CONTESTED\` (disputa). Estado de posesión coherente, nunca doble dueño.
En recepción: contacto legal con distancia + trayectoria + dirección relativa + tiempo; amortiguar velocidad **relativa al jugador** \`v_rel = v_ball - v_player\`, no reducir velocidad global arbitrariamente. Q ofrece mayor amortiguación a costa de velocidad/tiempo de preparación.
En conducción: objetivo de balón frente al pie con control con fuerza limitada:
\`F_virtual = k_p*(targetFoot - ballPos) - k_d*(ballVel - playerVel)\`; **no teletransportar** pelota ni aplicar atracción a larga distancia. La respuesta debe permitir robos, errores y rebotes.

### C. Fintas/regates
D breve + flecha: cambio de pie/lateral; D doble toque: amago/detención-rearranque; D manteniendo + flecha: movimiento más protegido pero lento. Un recurso por regate: tiempo de recuperación, ventana vulnerable, velocidad de entrada y probabilidad de pérdida contextual, no RNG oculto que niegue habilidad. La ventana y el contacto defensivo decidirán resultado.

### D. Tiros y pases
\`u=clamp((t_press - t_min)/(t_max - t_min),0,1)\`  
\`power=smoothstep(u)\`  
\`v_shot=v_min+(v_max-v_min)*power\`  
**Probar** \`t_min ~0.07s\` y \`t_max ~0.65s\`; valores de partida orientativos, NO parámetros científicos determinados. El ángulo viene de la flecha/último facing y ajuste fino hacia arco si se desea; precisión y dispersión dependen de presión, movimiento, preparación y control, no un autoaim completo.
Pases: objetivo viable según orientación, línea abierta y tiempo de intercepción rival; A pase al pie, W al espacio o elevado; asistentes suaves sólo dentro del cono de pase, el balón siempre puede ser interceptado; evitar cambiar la física en vuelo para acertar.
La resistencia sobre césped \`dv/dt = -k v\` (solución exponencial) sirve para distancia recorrida y elección de velocidad de pase. En 2.5D la variable \`h\` permitiría lob y rebote en iteración posterior.

### E. Defensa y barrida
A: entrada corta, precisa y de bajo riesgo. D: barrida con estados \`WINDUP→ACTIVE→RECOVERY\`, avance direccional, colisión barrida con balón y cuerpo; contacto con pelota y orden temporal antes del cuerpo determinan robo, rebote o infracción/penalización arcade. Fallo debe dejar una ventana de recuperación (sin spam); no permitir barrida infinita ni giro brusco a mitad de entrada.
E: velocidad alta a cambio de mayor radio de pérdida o recuperación de energía si el juego lo requiere. Evitar stamina pay-to-win.

## 7. Diseño de 2v2

- **Primer objetivo:** 2 jugadores por equipo en campo, 1 humano + 1 IA frente a 2 IA, con cambio Q fuera de posesión. No porteros humanos inicialmente.
- AI teammate: roles complementarios \`SUPPORT\`, \`RUN_INTO_SPACE\`, \`MARK\`, \`PRESS\`, \`COVER\`, \`INTERCEPT\`.
- IA detecta líneas de pase usando tiempos de llegada, no solo distancias.
- Defensor 1 sale al portador, defensor 2 cubre ángulo o compañero rival y línea central. Reajustar rol cuando cambia el balón.
- Evitar injusticia por orden de actualización: calcular decisiones sobre snapshot común, resolver comandos/contactos y después integrar movimientos/colisiones.
- 2v2 **online** es hito separado: 4 humanos autoritativos después de un prototipo de 4 entidades y tests de latencia; opcional 2 humanos + 2 IA como transición.
- Mapas/porterías y escalado de velocidades deberán revisarse: las dimensiones actuales 20×32 hacen 2v2 viable, pero no está demostrado que sea óptimo.

## 8. Orden de desarrollo para siguiente fase (aún NO autorizado para arrancar desde este estudio)

| Lote | Entrega | Criterio de aceptación |
|---|---|---|
| M01 | Simulación pura fija, input nuevo, tests | 30/60/120 FPS producen resultados equivalentes para inputs idénticos; replay determinista; no Espacio/Shift |
| M02 | Aceleración/giro/sprint, cámara y avatar | Controles responden sin latencia aparente; giro coherente; sin atravesar paredes |
| M03 | Posesión, primer toque, conducción y fintas | Receptor controla pases sin magnetismo injusto; robo y pérdida posibles; balón nunca con dos dueños |
| M04 | Disparo cargado | Tap vs hold varían velocidad, ambos dirigibles; barra visual; no disparos automáticos al mantener |
| M05 | Pase corto, pase al hueco/elevado, interceptación | Triangulaciones posibles, pases incorrectos fallan, defensores interceptan previsiblemente |
| M06 | Entrada, barrida, recuperación | Barrida fallo genera vulnerabilidad; colisiones y recuperación testables; sin spam ni ghost tackles |
| M07 | 2v2 humano+IA vs 2IA | Cambiar jugador, compañero apoya, defensores se reparten roles, goles válidos, rendimiento browser |
| M08 | 2v2 online / salas privadas / luego ranked | Cuatro conexiones, servidor autoritativo, scoring único, pruebas 50/100/150/250ms RTT y jitter |

## 9. Tests obligatorios antes de declarar Alpha 0.2 apta

- Pruebas unitarias de cada estado y transición; reposición tras gol y reinicio.
- Distintos FPS, ventanas inactivas, sim 60 Hz sin desacople y sin divergencia de inputs.
- 1.000 partidos sintéticos con semilla fija y logs de distribución de goles, posesión, pases, barridas y faltas/recuperaciones.
- No física duplicada por cambios de frame, no balones atravesando paredes/postes ni partidos con marcadores inventados.
- Receptor de pase: medir éxito según ángulo, velocidad relativa y presión con pruebas parametrizadas.
- Disparo: curva de potencia monótona vs tiempo de carga; precisión bajo presión; dirección consistente.
- IA: comparar regresión entre distintas seeds y ambos lados, detectar ventaja por orden de actualización o spawn.
- Online: propietario único, validación de entradas, pérdida/reconexión, observabilidad y sensibilidad a latencia. Incluir carga y costes antes de infraestructura de pago.
- Visual: desktop + móvil, feedback instantáneo en HUD, cap FPS para móviles, sin descargas instalables.
- Seguridad/IP: assets 100% propios o con licencias separadas verificadas; referencias no transfieren autorización sobre marcas/imágenes.

## 10. Decisiones recomendadas

1. Conservar estética 3D y la pista actual.
2. No copiar código de un juego completo; aprovechar arquitectura, ideas y citas de licencias como referencias. Si se incorporase fragmento MIT/Apache, conservar aviso de copyright y atribución; LGPL requiere evaluación adicional.
3. Hacer M01–M03 antes de shots/passes/tackles porque eliminan inconsistencias de base.
4. Hacer 2v2 con IA antes de 2v2 multijugador humano.
5. No desplegar ni programar mecánicas hasta pasar esta revisión; la rama principal de MatchMake y el servicio financiero permanecen intactos.
6. No requerir instalaciones locales; todo código y CI en GitHub/Render.
