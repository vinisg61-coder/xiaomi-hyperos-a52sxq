# Pesquisa de donor — HyperOS 2 / Android 15

O alvo solicitado para esta iteração é **HyperOS 2 baseado em Android 15**. A compatibilidade de userspace deve ser analisada separadamente da compatibilidade de hardware: o Samsung Galaxy A52s permanece em `a52sxq`, SM-A528B e SM7325, enquanto o kernel, DTB/DTBO, vendor e HALs continuam nativos do aparelho.

| Fonte | Evidência pública | Uso no projeto | Decisão |
| --- | --- | --- | --- |
| Xiaomi 11 Lite 5G NE (`lisa`) | Snapdragon 778G / SM7325 e árvore pública de device | Comparar configuração Qualcomm, overlays e organização de blobs | Comparador de plataforma; não substituir o hardware do A52s |
| Xiaomi 13 Pro (`nuwa`) | README registra atualização para HyperOS baseado em Android 15; Snapdragon 8 Gen 2 | Comparar estrutura Android 15/HyperOS, sepolicy, listas de blobs e framework | Donor potencial de userspace somente, com origem autorizada |
| Redmi 15 4G / POCO M7 4G (`creek`) | README registra Android 15 / HyperOS 2; Snapdragon 685 / SM6225-AD | Confirmar existência de árvores públicas que documentam HyperOS 2 | Não usar como base de hardware ou HAL no A52s |

A árvore `nuwa` documenta Android 15/HyperOS, mas usa uma plataforma muito diferente; portanto, qualquer uso futuro deve ser limitado ao userspace e acompanhado de patches de compatibilidade. A árvore `creek` é de recovery e está arquivada, servindo como evidência documental, não como base de ROM. `lisa` continua o comparador Qualcomm mais próximo, embora a árvore consultada não seja prova de HyperOS 2.

O pipeline não baixa uma ROM proprietária de URL desconhecida. Para um build HyperOS 2 real, será necessário fornecer `HYPEROS_SOURCE_URL`, `HYPEROS_SOURCE_REF`/`HYPEROS_SOURCE_COMMIT` e, quando possível, `HYPEROS_SOURCE_SHA256`, além do vendor/firmware do A52s obtido de fonte autorizada. Sem isso, o resultado é somente infraestrutura e bring-up verificável.

## Referências

[1]: https://github.com/PixelOS-Devices-old/device_xiaomi_lisa "Árvore do Xiaomi 11 Lite 5G NE (lisa)"
[2]: https://github.com/TheMysticle/android_device_xiaomi_nuwa-unofficial "Árvore não oficial do Xiaomi 13 Pro (nuwa)"
[3]: https://github.com/chkndrp/device_xiaomi_sm6225ad-recovery "Árvore de recovery para dispositivos SM6225-AD, incluindo creek"
