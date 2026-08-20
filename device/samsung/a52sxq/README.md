# Device tree placeholder — `a52sxq`

Este diretório é o ponto de integração da árvore Samsung A52s. A fonte pública fixada em `config/sources.env` deve ser sincronizada para o workspace do build e validada para conter o codinome `a52sxq`/modelo SM-A528B.

Não há uma `BoardConfig.mk` completa neste repositório porque a árvore de device precisa ser importada de uma fonte compatível e revisada junto com kernel, vendor, firmware e versão Android. O pipeline falha com uma mensagem explícita se esse diretório continuar sem os arquivos de build esperados.

## Requisitos mínimos

- `AndroidProducts.mk` ou equivalente do sistema de build;
- `BoardConfig.mk` com partições e boot image coerentes;
- `device.mk`/produto para `a52sxq`;
- manifests VINTF e init scripts compatíveis;
- lista de blobs e licença/proveniência;
- DTB/DTBO e kernel correspondentes ao firmware do aparelho.
