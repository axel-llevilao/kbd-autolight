# kbd-autolight

**Retroiluminación automática del teclado para el Lenovo Yoga Slim 7 ProX 14ARH7 (tipo 82TL) en Linux.**
*English below.*

En Windows, Lenovo Vantage enciende el teclado cuando oscurece. En Linux nadie conecta el sensor de luz del equipo con el teclado, así que esta herramienta lo hace:

| Luz ambiente | Teclado |
|---|---|
| Oscuro (menos de ~20 lux) | Nivel alto |
| Penumbra (~20–100 lux) | Nivel bajo |
| Iluminado (más de ~100 lux) | Apagado |

- **Sin root.** Corre como servicio de usuario de systemd y cambia el brillo a través de UPower, igual que KDE Plasma. El deslizador de brillo de Plasma y su indicador en pantalla reflejan los cambios.
- **Respeta tus ajustes.** Si cambias el brillo con **Fn + Espacio** o desde Plasma, se pausa 10 minutos.
- **Sin parpadeos.** Promedia varias lecturas y usa histéresis alrededor de cada umbral.
- **Applet para la bandeja de Plasma 6**, con interruptor, luz ambiente actual y nivel del teclado, traducido a 30 idiomas.
- No toca el teclado con la tapa cerrada, y al volver de la suspensión espera unos segundos antes de actuar.

## Requisitos

- Lenovo Yoga Slim 7 ProX 14ARH7 (82TL). En otros equipos se instala igual, pero solo funciona si tienen un sensor de luz IIO y un teclado retroiluminado que UPower pueda controlar.
- Debian 12/13, Ubuntu 23.04 o posterior, o derivadas, con systemd y UPower.
- KDE Plasma 6 para el applet (el servicio funciona en cualquier escritorio).

## Instalación

Descarga el `.deb` de la sección *Releases* e instálalo:

```bash
sudo apt install ./kbd-autolight_1.0.0_all.deb
```

Después:

1. Haz clic derecho en la bandeja del sistema → **Configurar bandeja del sistema** → **Entradas**, busca **Ajuste automático de brillo del teclado** y elige **Mostrar siempre**.
2. Abre el applet y activa el interruptor. Queda activo en cada inicio de sesión.

Sin el applet, desde la terminal:

```bash
kbd-autolight enable     # activar (ahora y en cada inicio de sesión)
kbd-autolight disable    # desactivar
kbd-autolight status     # estado actual en JSON
kbd-autolight resume     # cancelar la pausa tras un cambio manual
```

Clic central sobre el icono del applet también activa o desactiva el ajuste.

## Configuración

Los umbrales están calibrados para este modelo. Para cambiarlos, copia el archivo de ejemplo a tu carpeta y edítalo:

```bash
cp /etc/kbd-autolight.conf ~/.config/kbd-autolight.conf
systemctl --user restart kbd-autolight
```

| Opción | Por defecto | Qué hace |
|---|---|---|
| `dark_lux` | 20 | Bajo este valor, el teclado va al nivel alto |
| `dim_lux` | 100 | Bajo este valor, nivel bajo; sobre él, apagado |
| `margin` | 0.3 | Histéresis (±30 %) alrededor de cada umbral |
| `interval` | 2 | Segundos entre lecturas |
| `samples` | 3 | Lecturas que se promedian |
| `manual_pause` | 600 | Segundos de pausa tras un cambio manual |

Para ver qué mide el sensor en tu entorno:

```bash
systemctl --user stop kbd-autolight
kbd-autolight run --debug
```

## Problemas comunes

- **Ver el registro:** `journalctl --user -u kbd-autolight -f`
- **El applet no aparece:** revisa *Configurar bandeja del sistema → Entradas*. Si sigue sin aparecer, cierra y vuelve a abrir la sesión.
- **Se pausa sola a veces:** si en *Configuración del sistema → Gestión de energía* tienes un brillo de teclado por perfil, KDE lo cambia y el servicio lo interpreta como un ajuste manual. Desactiva esa opción.
- **Desinstalar:** primero `kbd-autolight disable`, después `sudo apt remove kbd-autolight`.

## Construir el paquete

```bash
sudo apt install dpkg-dev gettext
./build-deb.sh                       # deja el .deb en build/
python3 -m unittest discover tests   # pruebas sin hardware
```

Si publicas tu propia versión (un *fork*), cambia `MAINTAINER` y `HOMEPAGE` al inicio de `build-deb.sh`, y `Website` en `plasmoid/metadata.json`.

## Estructura

```
src/kbd-autolight            servicio y comandos (Python, sin dependencias externas salvo PyGObject)
systemd/                     unidad de servicio de usuario
config/kbd-autolight.conf    configuración de ejemplo
plasmoid/                    applet de Plasma 6 (QML)
po/                          traducciones del applet
packaging/                   control, postinst y página de manual del .deb
tests/                       pruebas
build-deb.sh                 construye el .deb
```

## Traducciones

El applet está traducido a: alemán, árabe, catalán, checo, chino (simplificado y tradicional), coreano, danés, eslovaco, español, finés, francés, gallego, griego, hebreo, húngaro, indonesio, inglés, italiano, japonés, neerlandés, noruego, polaco, portugués (Portugal y Brasil), rumano, ruso, sueco, turco, ucraniano y vietnamita. Los idiomas sin traducción se muestran en inglés.

Para agregar o corregir un idioma, copia `po/kbd-autolight.pot` a `po/<código>.po`, completa los `msgstr` y abre un *pull request*.

## Licencia

MIT. Puedes usarlo, modificarlo y redistribuirlo libremente. Ver [LICENSE](LICENSE).

---

## English

**Automatic keyboard backlight for the Lenovo Yoga Slim 7 ProX 14ARH7 (type 82TL) on Linux.**

Reads the laptop's ambient light sensor and sets the keyboard backlight: high in the dark, low in dim light, off in a lit room. It runs as a systemd user service (no root), talks to the keyboard through UPower like KDE Plasma does, pauses for 10 minutes when you change the brightness by hand (Fn + Space or the Plasma slider), and ships a Plasma 6 system tray applet with an on/off switch, translated into 30 languages.

**Install:** `sudo apt install ./kbd-autolight_1.0.0_all.deb`, then enable the applet under *Configure System Tray → Entries* and turn the switch on — or run `kbd-autolight enable`.

**Configure:** copy `/etc/kbd-autolight.conf` to `~/.config/kbd-autolight.conf`, edit it, then `systemctl --user restart kbd-autolight`.

**Build:** `sudo apt install dpkg-dev gettext && ./build-deb.sh`. Tests: `python3 -m unittest discover tests`.

**Logs:** `journalctl --user -u kbd-autolight -f`.

Other laptops: it installs anywhere, and works if the machine has an IIO ambient light sensor and a keyboard backlight that UPower can control. Thresholds may need tuning.

Translations are welcome: copy `po/kbd-autolight.pot` to `po/<lang>.po` and open a pull request.

MIT licensed.
