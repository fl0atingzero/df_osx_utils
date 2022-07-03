Нативная сборка Doom 2D: Forever под OS X
====================================

*В этой инструкции предполагается, что вы используете MacPorts в качестве менеджера пакетов. Если вы используете Homebrew, вы должны найти соответствующие пакеты сами*


1. Установите необходимые зависимые пакеты с MacPorts:

`$ sudo port install libsdl2 libsdl2_mixer miniupnpc macdylibbundler autoconf`

2. Скачайте исходники `libenet` и соберите их, я рекомендую использовать /opt/local в качестве префикса, т.к. это стандартный путь, куда MacPorts устанавливает пакеты:

`$ git clone https://github.com/lsalzman/enet.git && cd enet`
`$ autoreconf -vfi`
`$ ./configure --prefix="/opt/local/" && make && make install`

3. Проверьте, установлен ли у вас FPC. Он может быть установлен из MacPorts или вручную с официального сайта

4. Отредактируйте `builder.sh` в данном репозитории, выбрав `PACKUTIL` (утилита, с помощью которой скрипт будет собирать DMG - `mkisofs` (пакет `cdrtools` в MacPorts) или `genisoimage`), проверьте правильность установленных флагов

`https://github.com/fl0atingzero/df_osx_utils.git`

5. Соберите игру с помощью `builder.sh`:

`builder.sh -s path/to/game/sources -r path/to/game/resources -p -y`
