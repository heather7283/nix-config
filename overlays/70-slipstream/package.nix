# slipstream — высокопроизводительный covert-канал поверх DNS на QUIC multipath.
# Упаковка для Nix/NixOS, зафиксирована на релизе v0.1.1 (397850b1).
#
# Сборка без flakes:
#   nix-build -E '(import <nixpkgs> {}).callPackage ./default.nix {}'
# Сборка через flake (см. flake.nix):
#   nix build .#slipstream
#
# Особенности апстрима, учтённые здесь:
#   * Meson собирает picoquic как CMake-субпроект (cmake.subproject), поэтому
#     cmake нужен в nativeBuildInputs, а его авто-конфигурацию нужно глушить
#     (dontUseCmakeConfigure), иначе фазы configure конфликтуют.
#   * slipstream включает у picoquic PICOQUIC_FETCH_PTLS=ON, из-за чего CMake
#     через FetchContent скачивает picotls ИЗ СЕТИ на этапе configure. В nix
#     песочнице сети нет, поэтому picotls подставляется локально через
#     FETCHCONTENT_SOURCE_DIR_PICOTLS (см. postPatch). ВАЖНО: чекаут picotls
#     кладётся ВНУТРЬ subprojects/picoquic/, иначе Meson отбрасывает исходники
#     таргетов, лежащие вне корня CMake-проекта (проверено: пустые
#     static_library и отсутствующий -I путь до picotls.h).
#   * picotls безусловно собирает тестовые бинари, которым нужен его
#     сабмодуль deps/picotest — он тоже вендорится.
#   * brotli у picotls опционален и в апстримном Docker-образе отсутствует,
#     поэтому в деривации он сознательно не добавлен (как у апстрима).
#   * meson.build не объявляет install-правила для исполняемых файлов
#     (Dockerfile апстрима копирует бинари вручную), поэтому свой installPhase.
#
# Как обновить версию:
#   1. Поменяйте `version` и хэш srcs.slipstream.
#   2. Обновите пины сабмодулей: `git submodule status` на новом теге
#      (см. .gitmodules апстрима).
#   3. picotls: возьмите GIT_TAG из subprojects/picoquic/CMakeLists.txt
#      (FetchContent_Declare picotls).
#   4. picotest: sha сабмодуля deps/picotest в репозитории picotls на этом
#      коммите (`git submodule status` в picotls).
{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  cmake,
  pkg-config,
  openssl,
}:

let
  version = "0.1.1";

  # Все зависимости зафиксированы на точные коммиты, как у апстрима
  # (git-сабмодули + пин picotls из CMakeLists picoquic-форка).
  srcs = {
    slipstream = fetchurl {
      url = "https://github.com/EndPositive/slipstream/archive/refs/tags/v${version}.tar.gz";
      hash = "sha256-N0Iu0u+O/rTHYcMsv7l2jH8xbLjZ/hw9k5KOBkLtd1M=";
    };

    # git-сабмодули slipstream (v0.1.1)
    picoquic = fetchurl {
      url = "https://github.com/EndPositive/slipstream-picoquic/archive/2ee2ecd189354791e15cc1ff9db86e4e4b8eba10.tar.gz";
      hash = "sha256-vlxP98jQQd8Q+IbRVBZEjjMe5vFrDqOCwGoW1wqiq5A=";
    };
    spcdns = fetchurl {
      url = "https://github.com/spc476/SPCDNS/archive/d291537e1f66b4a7ede069b949a8db0f94c59246.tar.gz";
      hash = "sha256-oroth0UQkuEAhRsqck2l+T58yUwDeRHt5GpvW6bnzXs=";
    };
    luaEnc = fetchurl {
      url = "https://github.com/EndPositive/lua-resty-base-encoding/archive/bd9246f681806b26469e0d874c893dcab4975aeb.tar.gz";
      hash = "sha256-oQmNTNKi8rT1pEkcc8i9gSiBU1SVg7UTu3Uftx2WiI0=";
    };
    quickArg = fetchurl {
      url = "https://github.com/Dugy/quick_arg_parser/archive/153b0accc1f0201df9d2fd169bafaeee53e6f300.tar.gz";
      hash = "sha256-SIJVvBd4erUUcgOMevk/5ogVkKqcRJ4WRpqZb5jPPcs=";
    };

    # picotls — пин из FetchContent_Declare в CMakeLists.txt picoquic-форка
    picotls = fetchurl {
      url = "https://github.com/h2o/picotls/archive/5a4461d8a3948d9d26bf861e7d90cb80d8093515.tar.gz";
      hash = "sha256-AgoW5Y46gY34YHdG1dtzGf39wqKFvn5M5NlTtRTiEPs=";
    };
    # сабмодуль picotls, нужен его сборке (тестовые таргеты собираются всегда)
    picotest = fetchurl {
      url = "https://github.com/h2o/picotest/archive/a99858e0c33b97b24cd09ceae729f2be33ec01e1.tar.gz";
      hash = "sha256-88QtmIyM0a8k3uLmbOgy8+JXu3dm40FnSZlUwWBMgsA=";
    };
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "slipstream";
  inherit version;

  src = srcs.slipstream;

  strictDeps = true;

  nativeBuildInputs = [
    meson
    ninja
    # Meson собирает picoquic как CMake-субпроект; хук cmake также
    # наполняет CMAKE_PREFIX_PATH, чтобы find_package(OpenSSL) сработал.
    cmake
    pkg-config
  ];

  buildInputs = [
    # picoquic/picotls: find_package(OpenSSL REQUIRED)
    openssl
  ];

  # Не даём хуку cmake запустить собственную конфигурацию поверх meson.
  dontUseCmakeConfigure = true;

  # Апстрим (Dockerfile) собирает с --buildtype=release.
  mesonBuildType = "release";

  postPatch = ''
    # Вендорим git-сабмодули апстрима в исходники.
    mkdir -p subprojects/picoquic extern/SPCDNS extern/lua-resty-base-encoding extern/quick_arg_parser
    tar -xzf ${srcs.picoquic} -C subprojects/picoquic           --strip-components=1
    tar -xzf ${srcs.spcdns}   -C extern/SPCDNS                  --strip-components=1
    tar -xzf ${srcs.luaEnc}   -C extern/lua-resty-base-encoding --strip-components=1
    tar -xzf ${srcs.quickArg} -C extern/quick_arg_parser        --strip-components=1

    # picotls: вместо FetchContent-скачивания из сети подставляем локальный
    # пиновый чекаут. Кладём его ВНУТРЬ subprojects/picoquic/ — вне корня
    # CMake-проекта Meson теряет исходники и include-пути его таргетов.
    # deps/picotest нужен сборке picotls (тестовые таргеты собираются всегда).
    mkdir -p subprojects/picoquic/picotls/deps/picotest
    tar -xzf ${srcs.picotls}  -C subprojects/picoquic/picotls               --strip-components=1
    tar -xzf ${srcs.picotest} -C subprojects/picoquic/picotls/deps/picotest --strip-components=1

    # Добавляем определение в список add_cmake_defines() в meson.build
    # (прямо после включения PICOQUIC_FETCH_PTLS).
    sed -i "s|{'PICOQUIC_FETCH_PTLS': 'ON'},|{'PICOQUIC_FETCH_PTLS': 'ON'},\n{'FETCHCONTENT_SOURCE_DIR_PICOTLS': '$PWD/subprojects/picoquic/picotls'},|" meson.build
  '';

  # У апстрима нет install-правил для исполняемых файлов — ставим вручную.
  installPhase = ''
    runHook preInstall
    install -Dm0755 slipstream-client $out/bin/slipstream-client
    install -Dm0755 slipstream-server $out/bin/slipstream-server

    # Dockerfile апстрима кладёт в образ ./certs — демонстрационную пару
    # TLS-сертификат/ключ для slipstream-server. По умолчанию не ставим:
    # серверу пути к своим сертификатам передаются флагами CLI.
    # mkdir -p $out/share/slipstream
    # cp -r certs $out/share/slipstream/certs

    runHook postInstall
  '';

  meta = with lib; {
    description = "High-performance covert channel over DNS, powered by QUIC multipath";
    longDescription = ''
      Slipstream is a high-performance covert channel over DNS, powered by
      QUIC multipath. It provides slipstream-client and slipstream-server
      binaries with adaptive congestion control for rate-limited resolvers
      and parallel routing over multiple resolvers.
    '';
    homepage = "https://github.com/EndPositive/slipstream";
    changelog = "https://github.com/EndPositive/slipstream/releases/tag/v${finalAttrs.version}";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "slipstream-client";
  };
})
