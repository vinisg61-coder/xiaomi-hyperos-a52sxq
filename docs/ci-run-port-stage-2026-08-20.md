# Run de staging do port HyperOS 2 / Android 15 — 20 de agosto de 2026

## Resultado executivo

O workflow `a52sxq bring-up build` foi executado com `BUILD_MODE=port-stage` no run [#24](https://github.com/vinisg61-coder/xiaomi-hyperos-a52sxq/actions/runs/32424489392), usando o commit `e2d8891` e concluindo com sucesso em aproximadamente 16 minutos e 40 segundos. O resultado confirma a montagem automatizada do bundle híbrido para o Samsung Galaxy A52s 5G, mas não constitui uma ROM pronta para flash.

> O artefato continua deliberadamente marcado como `flashable=false` e `boot_confirmed=false`. O run valida a estrutura e a origem dos componentes; não valida boot físico, AVB, VINTF, SELinux, init ou funcionamento dos periféricos no SM-A528B.

## Parâmetros e origem dos componentes

| Campo | Valor | Evidência |
|---|---|---|
| Dispositivo | `a52sxq` / `SM-A528B` | [config/project.env](../config/project.env) |
| Plataforma | Qualcomm `sm7325` / Snapdragon 778G | [device tree](../device/samsung/a52sxq/BoardConfig.mk) |
| Android alvo | 15 | [workflow build.yml](../.github/workflows/build.yml) |
| HyperOS donor | 2.0.215 | [port stage](../scripts/port_stage.sh) |
| Userspace | `CraftyOs_China_HOTFIX.zip`, donor `super.img.zst` | [fontes do port](./port-sources.md) |
| Hardware | `A528BXXS6FXA1_BTU` | [fontes do port](./port-sources.md) |
| Kernel/boot/DTBO/vendor_boot/vbmeta/vendor | Origem nativa Samsung | [fetch_a52sxq_native.sh](../scripts/fetch_a52sxq_native.sh) |
| Estado | `port-staging`, não-flashável | [package.sh](../scripts/package.sh) |

O donor fornece somente o userspace pré-compilado. O kernel Xiaomi e as imagens de hardware Xiaomi não são usados no A52s; as imagens de boot e vendor são mantidas nativas do SM-A528B, conforme a política de segurança do projeto.

## Artefato produzido

O artifact publicado foi `a52sxq-port-stage-24`, com tamanho de **5.247.582.833 bytes**. A correção do commit `e2d8891` removeu a duplicação de `out/port/` no passo de upload: o pacote compactado já contém esse diretório, portanto o workflow passou a enviar o tarball e os relatórios sem repetir as mesmas imagens no nível externo.

| Item | Resultado |
|---|---:|
| Tamanho do artifact GitHub | 5.247.582.833 bytes |
| Membro principal | `dist/a52sxq-port-staging-32424489392.tar.gz` |
| Tamanho descompactado do tarball | 5.275.371.290 bytes |
| SHA-256 do tarball | `d65b85f02831e8ebfb30a2c721d7d2202ba44e41ec5fa82a854ca7d8e59d7cf6` |
| Tipo | `port-staging` |
| Imagens declaradas | 5 |
| `flashable` | `false` |
| Erros da verificação | 0 |

Os cinco membros externos do artifact são o tarball de staging, seu checksum, `package.properties`, `out/build-report.txt` e `out/verify/build-report.txt`. O tarball contém as cinco imagens nativas e as partições lógicas extraídas do donor, além dos manifestos e metadados. O donor `super.img` intermediário não é publicado como arquivo separado.

## Verificação estrutural

A etapa `Verify result` concluiu com `errors=0`. Ela confirmou a identidade `a52sxq`, o modelo `SM-A528B`, a plataforma `sm7325`, os diretórios de device/vendor/kernel/proprietary/overlays, a existência dos pins de origem, a documentação de bring-up, a ausência de credenciais óbvias e a ausência de symlinks quebrados. O próprio relatório mantém dois avisos esperados: as imagens não são consideradas resultado flashável e o manifesto proprietário/full build ainda não está completo.

## Comparação com o vendor nativo

A comparação local utilizou o `vendor.img` da release `A528BXXS6FXA1_BTU` e o manifesto [device/samsung/a52sxq/proprietary-files.txt](../device/samsung/a52sxq/proprietary-files.txt). O inventário nativo contém 3.126 arquivos regulares. Dos 2.087 itens do manifesto, 1.940 apontam para `vendor/`; 1.890 desses caminhos estão presentes exatamente no vendor nativo e 50 estão ausentes. Outros 147 itens apontam para `system_ext/` ou outra partição e não podem ser validados apenas contra `vendor.img`.

| Categoria | Quantidade | Interpretação |
|---|---:|---|
| Entradas totais do manifesto | 2.087 | Blobs declarados pela device tree |
| Entradas destinadas a `vendor/` | 1.940 | Comparáveis diretamente com `vendor.img` |
| Presentes exatamente no vendor nativo | 1.890 | Base nativa reutilizável |
| Ausentes no vendor nativo | 50 | Precisam ser reavaliados, extraídos de outra partição/release ou removidos do manifesto |
| Outras partições, principalmente `system_ext/` | 147 | Exigem mapeamento separado de framework e partições lógicas |

Os 50 ausentes concentram-se em quatro áreas de risco. A primeira é a câmera, com implementações Samsung de provider/HAL e bibliotecas de pré-processamento. A segunda é a pilha gráfica Qualcomm Adreno/GLES. A terceira é a integração de rede e rádio, incluindo `init.vendor.rilchip.rc` e variantes de firmware WLAN. A quarta reúne utilitários e configurações de áudio que podem ser específicos da release ou já ter sido substituídos por equivalentes presentes no vendor nativo.

## O que ainda bloqueia um ZIP flashável

O bundle atual é uma base de bring-up, não uma ROM instalável. Ainda é necessário reconciliar o userspace HyperOS com o boot nativo Samsung em `init`, propriedades de hardware, namespaces, VINTF, SELinux, permissões, HALs de câmera/áudio/radio, layout de partições dinâmicas e AVB. Também será necessário gerar um pacote de flash apropriado ao esquema de partições do A52s e testar no dispositivo real com recuperação de emergência disponível.

A sequência segura é testar primeiro imagens de bring-up não anunciadas como flasháveis, coletar logs de boot e corrigir incompatibilidades por subsistema. Somente depois de um boot físico repetível e de testes básicos de tela, toque, áudio, câmera, rádio, Wi-Fi, Bluetooth, sensores, armazenamento e reinicialização será aceitável alterar as flags para `flashable=true` e `boot_confirmed=true`.

## Referências

[1]: https://github.com/vinisg61-coder/xiaomi-hyperos-a52sxq/actions/runs/32424489392 "Run #24 do workflow port-stage"
[2]: ../.github/workflows/build.yml "Workflow principal do build"
[3]: ../scripts/port_stage.sh "Script de montagem do port híbrido"
[4]: ../scripts/package.sh "Empacotador do bundle"
[5]: ../scripts/verify.sh "Verificação estrutural"
[6]: ../device/samsung/a52sxq/proprietary-files.txt "Manifesto de blobs proprietários"
[7]: ./port-sources.md "Fontes confirmadas do port"
[8]: ../config/project.env "Identidade e versões do alvo"
