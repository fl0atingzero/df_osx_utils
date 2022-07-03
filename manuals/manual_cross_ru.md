Кросс-компиляция Doom 2D: Forever с Linux под OS X
============================================

*Примечание: эта инструкция была написана для использования в Arch Linux и с pacman. Если вы используете другой дистрибутив, вам следует самому найти соответствующие пакеты*

1. Для начала нам следует установить кросс-тулчейн `osxcross`. Склонируйте его репозиторий и поместить тарболл с Mac OS X SDK в каталог `tarballs`. Вы можете скачать его [здесь](https://github.com/phracker/MacOSX-SDKs). Я буду использовать SDK для Mac OS X 10.8 (`x86_64-apple-darwin12`):

`git clone https://github.com/tpoechtrager/osxcross`

2. Установите необходимые зависимые пакеты с помощью pacman:

`# pacman -S base-devel fpc clang cmake libxml2 openssl cpio curl`

3. Установите переменную окружения `TARGET_DIR` - путь, куда должен быть установлен тулчейн, и соберите его, после этого добавьте `$TARGET_DIR` в `PATH`:

`# TARGET_DIR=/usr/local/osxcross ./build.sh`

4. Скачайте исходники FPC и соберите кросс компилятор. `CROSSBINDIR` - путь к каталогу кросс-компилятора, `CPU_TARGET` и `BINUTILSPREFIX` зависят от выбранного SDK, целевой каталог установки в моем случае - `/opt/cross`:

`$ curl -O ftp://ftp.hu.freepascal.org/pub/fpc/dist/3.2.2/source/fpc-3.2.2.source.tar.gz`
`$ tar -xzvf fpc-3.2.2.source.tar.gz`
`$ cd fpc-3.2.2`
`# make distclean && FPC=ppcx64 make crossall crossinstall \`
`CPU_TARGET=x86_64 OS_TARGET=darwin \`
`CROSSBINDIR=/usr/local/osxcross/bin/ BINUTILSPREFIX=x86_64-apple-darwin12- \`
`INSTALL_PREFIX=/opt/cross \`
`OPT="-gl -gw -godwarfsets -XX -CX -Xd -Fl/usr/local/osxcross/SDK/MacOSX10.8.sdk/usr/lib"`

После этого добавьте `/opt/cross/lib/fpc/3.2.2/` в `PATH`

5. Отредактируйте `macportsutil.sh` в данном репозитории (скрипт, который может скачать нужные библиотеки из MacPorts под нужную версию Darwin и поместить их в указанный каталог), указав `OUTDIR` - каталог, в который будут помещены скачанные библиотеки (в моем случае это `~/dfcross/libs`) и установив `FLAG_D` в 1, чтобы скрипт пропатчил библиотеки после загрузки и распаковки, после чего запустите его:

`$ git clone https://github.com/fl0atingzero/df_osx_utils.git`
`./macportsutil`

6. Склонируйте репозиторий `macdylibbundler` и соберите его, затем создайте символические ссылки на `otool` и `install_name_tool` для его корректной работы:

`$ git clone https://github.com/auriamg/macdylibbundler.git`
`$ cd macdylibbundler`
`$ make`
`$ sudo cp dylibbundler /usr/local/bin`
`$ ln -s /usr/local/osxcross/bin/{x86_64-apple-darwin12-otool,otool}`
`$ ln -s /usr/local/osxcross/bin/{x86_64-apple-darwin12-install_name_tool,install_name_tool}`

7. Скачайте исходники `libenet` и соберите их, я рекомендую использовать тот же `OUTDIR`, который был использован для `macportsutil`:

`$ git clone https://github.com/lsalzman/enet/commits/master`
`# pacman -S autoconf`
`$ cd enet`
`$ autoreconf -vfi`
`$ ./configure \`
`    --host="x86_64-apple-darwin12" \`
`    --target="x86_64-apple-darwin12" \`
`    --prefix="/home/vlad/dfcross/libs" \`
`    --with-sysroot="/usr/local/osxcross/SDK/MacOSX10.8.sdk/" \`
`    CC=x86_64-apple-darwin12-clang`

8. Отредактируйте `crossbuilder.sh` в данном репозитории, указав путь к исходникам игры, каталог ресурсов (обычно это распакованный архив win32-d2df-latest.zip), каталог временных файлов, выходной каталог, а также утилиту для упаковки DMG - `mkisofs` (пакет `cdrtools` в репозиториях Arch)  или `genisoimage`), проверьте правильность установленных флагов после чего соберите игру с помощью `crossbuilder.sh`

`./crossbuilder.sh`
