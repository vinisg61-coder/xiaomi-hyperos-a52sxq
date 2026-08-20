# Bring-up do `a52sxq`

## Objetivo operacional

O primeiro objetivo é gerar um conjunto de imagens coerente para o Samsung Galaxy A52s, validar a estrutura e então testar boot em hardware. O port deve conservar o stack nativo do A52s nas áreas de hardware e adaptar apenas a camada de userspace que tenha fonte e compatibilidade verificáveis.

## Fontes e proveniência

A árvore pública do A52s deve ser fixada por commit antes de cada build. A pesquisa inicial encontrou árvores de device, vendor e kernel mantidas por projetos comunitários; o workflow usa URLs configuráveis porque branches mudam e não devem ser seguidas implicitamente.

| Entrada | Variável | Obrigatória para pacote completo | Observação |
| --- | --- | ---: | --- |
| Device tree A52s | `A52S_DEVICE_URL`, `A52S_DEVICE_REF` | Sim | Deve identificar `a52sxq` e gerar `BoardConfig`/manifesto válidos. |
| Kernel/DTB/DTBO A52s | `A52S_KERNEL_URL`, `A52S_KERNEL_REF` | Sim | Deve ser compatível com SM7325, bootloader e configuração do modelo. |
| Vendor/firmware A52s | `A52S_VENDOR_URL` ou artifact privado | Sim | Blobs podem ser extraídos somente de dispositivo/dump autorizado. |
| Donor userspace HyperOS 2/Android 15 | `HYPEROS_SOURCE_URL`, `HYPEROS_SOURCE_REF` | Sim para HyperOS real | A origem deve ser autorizada, estável e acompanhada de hash. |
| Hashes | `*_SHA256` | Recomendado | O pipeline registra e verifica quando fornecido. |

O projeto não incorpora dumps proprietários ao Git. O usuário que possui o aparelho pode fornecer os arquivos por um artifact privado ou secret de curta duração, conforme os limites do GitHub e as licenças aplicáveis.

## Donor e compatibilidade

`lisa` é o comparador Qualcomm SM7325 inicial para manter a proximidade de plataforma. O alvo de userspace agora é HyperOS 2 sobre Android 15. `lisa` não fornece um kernel ou vendor intercambiável com o Samsung. Xiaomi 12, Redmi Note 13 Pro 5G e Xiaomi 15 continuam candidatos para userspace, desde que a versão Android/HyperOS, a arquitetura HAL e a disponibilidade legal dos arquivos sejam comparadas antes de uso.

A matriz de decisão inicial é:

| Candidato | Plataforma | Uso recomendado | Risco principal | Decisão inicial |
| --- | --- | --- | --- | --- |
| Xiaomi 11 Lite 5G NE (`lisa`) | SM7325 | Comparar configs, framework e componentes Qualcomm | Árvore arquivada e hardware diferente | **Base de comparação** |
| Xiaomi 12 (`cupid/zeus`, conforme origem) | Snapdragon 8 Gen 1 | Donor de userspace somente se Android/HyperOS coincidir | Plataforma e HAL diferentes | Candidato secundário |
| Redmi Note 13 Pro 5G | Snapdragon 7s Gen 2 | Donor de userspace somente | Plataforma diferente e arquivos proprietários | Candidato secundário |
| Xiaomi 15 | Snapdragon 8 Elite | Referência visual/framework em versões novas | Plataforma muito diferente | Não usar como hardware |

## Ordem de bring-up

O pipeline deve seguir a ordem abaixo:

1. Verificar toolchain, espaço, manifests e hashes.
2. Sincronizar fontes públicas fixadas.
3. Colocar device tree, kernel, DTB/DTBO e vendor do A52s em seus diretórios.
4. Aplicar overlays e patches mínimos, sem apagar arquivos aleatoriamente.
5. Construir imagens e um pacote de teste apenas quando os insumos essenciais existirem.
6. Verificar VINTF, manifests, partições, tamanho, symlinks e identidade do alvo.
7. Testar boot e coletar `dmesg`, `logcat`, `getprop`, `lshal`/`dumpsys` e AVCs.
8. Corrigir uma camada por vez e repetir o workflow.

## Critério de boot confirmado

`boot_confirmed` só pode ser definido quando houver, para um artefato identificado por SHA e commit:

```text
ro.product.device=a52sxq (ou identidade equivalente documentada)
system_server iniciou
SurfaceFlinger iniciou
SystemUI iniciou ou há evidência clara de avanço até a UI
SELinux reportado e modo registrado
logs persistidos no relatório de teste
```

A ausência de um teste físico não deve ser descrita como boot. O workflow marca o estado como `not_tested` até que o resultado seja anexado.

## Hardware após o primeiro boot

A validação posterior deve priorizar display, touch, áudio, Wi-Fi, Bluetooth, rede móvel/RIL, GPS, sensores, biometria, câmera, NFC, USB, carregamento, refresh rate, brilho, energia, térmica e VoLTE/VoWiFi. Para cada falha, o relatório deve indicar o serviço/HAL, a origem escolhida, o log que sustenta a hipótese e o patch aplicado.

## SELinux

Permissive pode ser utilizado apenas em um branch de depuração e nunca deve ser o estado final publicado. AVCs devem ser coletados, reduzidos a regras necessárias e validados novamente em enforcing.

## Alvo de versão e estado atual

O alvo de versão solicitado é **HyperOS 2 / Android 15**. A origem HyperOS deve ser fornecida por URL/ref/commit/hash autorizados; as árvores públicas do A52s e o comparador `lisa` não incluem, por si só, uma imagem HyperOS 2 redistribuível.

O repositório contém a infraestrutura inicial. Não há ainda donor HyperOS 2/Android 15 fornecido, blobs privados, imagens de kernel/vendor ou teste físico. O próximo run é deliberadamente um **bring-up/verification run**; ele não deve ser interpretado como prova de uma ROM bootável.
