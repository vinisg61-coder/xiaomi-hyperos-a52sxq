# Xiaomi HyperOS userspace port para Samsung Galaxy A52s (`a52sxq`)

Este repositório é uma base experimental e reproduzível para investigar a execução de componentes de userspace inspirados no Xiaomi HyperOS sobre o hardware nativo do Samsung Galaxy A52s 5G, codinome `a52sxq` / modelo SM-A528B. O projeto prioriza um **bring-up verificável**: cada etapa deve registrar fontes, hashes, entradas e artefatos, sem confundir um pacote de preparação com uma ROM flashável ou um boot confirmado.

> **Estado atual:** infraestrutura inicial criada; ainda não há imagem bootável nem evidência de boot neste repositório.

## Arquitetura

O projeto separa deliberadamente a experiência de userspace do suporte de hardware. O kernel, device tree, DTB/DTBO, vendor, firmware e HALs devem vir do A52s ou de fontes compatíveis com o A52s. Componentes Xiaomi são tratados como donor de framework, SystemUI, recursos e aplicações somente quando a licença, a origem e a compatibilidade permitirem.

| Camada | Origem preferencial | Regra de integração |
| --- | --- | --- |
| Kernel, DTB e DTBO | Samsung A52s / SM7325 | Nunca substituir pelo kernel de outro aparelho Xiaomi sem adaptação específica. |
| Vendor, firmware e HALs | A52s, extração do dispositivo do usuário ou fonte pública redistribuível | Não armazenar blobs proprietários sem autorização; o pipeline valida sua presença e aceita entradas privadas. |
| Framework e SystemUI | Donor Xiaomi/HyperOS documentado | Integrar apenas componentes e artefatos cuja origem e versão estejam registradas. |
| Overlays e patches | Este repositório | Manter alterações pequenas, reversíveis e explicadas. |
| Build e verificação | GitHub Actions | Execução manual, por push e por pull request, com relatórios e artefatos. |

## Donor inicial

A pesquisa inicial selecionou o **Xiaomi 11 Lite 5G NE (`lisa`) como comparador de plataforma**, não como fonte de hardware. Ele usa Snapdragon 778G 5G / SM7325 e oferece uma árvore pública com configuração de áudio, overlays, extração de blobs e integração de componentes Xiaomi. Como o A52s também usa a família SM7325, `lisa` é um ponto de comparação mais racional do que transportar indiscriminadamente um donor como Xiaomi 15. A árvore `lisa` consultada está arquivada; por isso, qualquer uso futuro deve fixar commit e validar a compatibilidade antes do build.

O donor de **userspace HyperOS** permanece parametrizável. O pipeline não baixa uma ROM proprietária de origem não verificada. Para uma tentativa real de port, será necessário fornecer uma origem autorizada e reproduzível por meio de `HYPEROS_SOURCE_URL`/`HYPEROS_SOURCE_SHA256` ou disponibilizar os artefatos privados exigidos como secrets/artifacts do GitHub. Sem esse material, o pipeline executa o bring-up e as verificações, mas não pode fabricar legal ou tecnicamente um sistema HyperOS completo.

## Estrutura

```text
.github/workflows/
  build.yml       # preparação e build manual/automatizado
  verify.yml      # lint, proveniência, manifesto e saneamento
  release.yml     # empacotamento somente em tag/manual

device/samsung/a52sxq/       # configuração e manifestos do alvo
vendor/samsung/a52sxq/        # interface para vendor/firmware do A52s
kernel/samsung/a52sxq/        # manifesto do kernel/DTB/DTBO; não contém blobs por padrão
proprietary/a52sxq/           # listas e metadados de arquivos privados
 overlays/a52sxq/              # overlays do alvo
patches/                      # patches separados por camada
scripts/                      # setup, sync, extract, patch, build, verify e package
docs/                         # pesquisa, decisões e relatórios
config/                       # manifests e defaults do pipeline
```

## Execução local

O fluxo de desenvolvimento é orientado a Linux e GitHub Actions. Para uma verificação sem downloads externos:

```bash
./scripts/setup.sh --check-only
./scripts/verify.sh --source-root . --report-dir out/verify
```

Para preparar fontes públicas e metadados:

```bash
export DONOR=lisa
export ANDROID_VERSION=14
export HYPEROS_VERSION=1.x
./scripts/sync.sh --workspace "$PWD/.work"
```

Para incluir arquivos privados extraídos de uma unidade que o usuário possui, use um diretório de entrada fora do Git e forneça-o explicitamente:

```bash
./scripts/extract.sh --input-dir /caminho/para/dump/autorizado --output-dir proprietary/a52sxq
./scripts/patch.sh --source-root .
./scripts/build.sh --source-root . --out-dir out --variant userdebug
./scripts/package.sh --input-dir out --output-dir dist
```

O script de build falha de propósito quando faltam manifestos, fontes ou blobs essenciais. Isso evita publicar um ZIP que parece flashável, mas não contém kernel, vendor ou imagens necessárias.

## GitHub Actions

Os workflows aceitam `workflow_dispatch` com as entradas `DONOR`, `ANDROID_VERSION`, `HYPEROS_VERSION`, `BUILD_VARIANT` e `CLEAN_BUILD`. O pipeline gera um relatório de proveniência, verifica que o alvo é `a52sxq`, testa tamanhos e nomes de artefatos e publica os resultados como artifacts do run.

O workflow não usa credenciais embutidas nem baixa automaticamente uma ROM proprietária de link desconhecido. Para uma tentativa de build completa, configure os secrets ou artifacts privados definidos em `docs/bringup.md` e aceite os termos aplicáveis às fontes utilizadas.

## Segurança, licenças e boot

O repositório contém apenas infraestrutura, configuração e metadados públicos. Não inclui firmware Samsung, vendor proprietário ou um dump HyperOS. O uso de blobs deve respeitar a licença e a posse do dispositivo. SELinux permissive, quando necessário, deve ser somente uma etapa temporária de depuração; o objetivo final é `Enforcing`.

Um **build bem-sucedido no GitHub Actions não prova boot**. A confirmação de boot exige testar o artefato em um A52s desbloqueado, coletar logs e registrar o resultado. O projeto só marcará `boot_confirmed` após evidência fornecida por teste físico ou logs de boot verificáveis.

## Referências

[1]: https://github.com/Alone0316/android_device_samsung_a52sxq "Árvore pública do Samsung Galaxy A52s a52sxq"
[2]: https://github.com/LineageOS/android_device_samsung_a52sxq "Árvore LineageOS do Samsung Galaxy A52s a52sxq"
[3]: https://github.com/PixelOS-Devices-old/device_xiaomi_lisa "Árvore pública do Xiaomi 11 Lite 5G NE lisa"
[4]: https://github.com/PixelExperience-Devices/kernel_samsung_sm7325 "Kernel comum SM7325 para dispositivos Samsung"
[5]: https://github.com/TheMuppets/proprietary_vendor_samsung_a52sxq "Vendor público comunitário do A52s"
