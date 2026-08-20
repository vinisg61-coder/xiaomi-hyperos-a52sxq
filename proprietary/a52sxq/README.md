# Blobs proprietários do Galaxy A52s (`a52sxq`)

A lista completa de arquivos proprietários esperados está em `device/samsung/a52sxq/proprietary-files.txt`, importada da árvore pública do A52s. Os binários não são commitados neste repositório.

Para o estágio híbrido do port, o workflow baixa e verifica duas entradas da release `A528BXXS6FXA1_BTU`:

| Entrada | SHA256 |
| --- | --- |
| `A528BXXS6FXA1_vendor.zip` | `dfc8acf78196d21287f137aa07e378cf9df0c6c55805fff1a81ec0c1dc0d3c43` |
| `A528BXXS6FXA1_kernel.tar` | `9175331267f196a19f6d1cf9cc489150ed615396af0e8aeb51972be08336eb04` |

O `vendor.zip` contém um `vendor.img` ext4 do SM-A528B; o `kernel.tar` contém `boot.img.lz4`, `dtbo.img.lz4`, `vendor_boot.img.lz4` e `vbmeta.img.lz4`. O script `fetch_a52sxq_native.sh` valida os hashes antes de extrair os arquivos.

O dump de firmware do A52s deve corresponder ao modelo e à região do aparelho que será testado. Não misture CSC, bootloader ou modem de outro modelo. Fonte: [Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq](https://github.com/Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq).
