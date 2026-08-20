# Primeiro teste full — HyperOS 2 / Android 15

## Resultado

O run manual `32382071564` do workflow `a52sxq bring-up build` foi disparado pela interface autenticada do GitHub com job identificado como `Prepare/build a52sxq (full)`. O commit executado foi `2c04092751e113735622a177c141d2280a1fab1c`, branch `main`, evento `workflow_dispatch`.

| Campo | Resultado |
| --- | --- |
| Donor de comparação | `lisa` |
| Android | `15` |
| HyperOS | `2.0` |
| Variante | `userdebug` |
| Modo | `full` |
| Sincronização das fontes A52s/lisa | Concluída |
| Imagens | Não geradas |
| Resultado | Falha controlada no pré-requisito HyperOS |

## Bloqueador observado

O log termina com:

```text
HYPEROS_SOURCE_URL não foi fornecida; build HyperOS completo não pode continuar.
```

O pipeline recusou prosseguir deliberadamente. Isso evita fabricar um pacote sem userspace HyperOS 2 ou baixar uma ROM proprietária de uma origem não autorizada. O bloqueio pode ser removido somente quando uma fonte autorizada e reproduzível for configurada como secret, com URL/ref/commit/hash conforme `docs/bringup.md`, e quando os blobs/vendor do A52s estiverem disponíveis.

## Interpretação

A execução comprova que o workflow aceita e propaga HyperOS 2/Android 15 e que as fontes públicas de device/kernel/vendor do A52s e o comparador `lisa` sincronizam. Ela não é um build Android completo, não produz imagens e não prova boot.

Link do run: https://github.com/vinisg61-coder/xiaomi-hyperos-a52sxq/actions/runs/32382071564
