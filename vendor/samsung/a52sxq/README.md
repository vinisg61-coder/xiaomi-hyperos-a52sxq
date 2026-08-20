# Vendor nativo do Samsung Galaxy A52s (`a52sxq`)

Esta camada não copia binários proprietários para o Git. O workflow baixa, valida por SHA256 e usa diretamente no runner o `vendor.img` da release pública `A528BXXS6FXA1_BTU` do repositório de firmware do A52s.

| Entrada | Valor |
| --- | --- |
| Modelo | `SM-A528B` |
| Plataforma | `sm7325` / Snapdragon 778G |
| Release | `A528BXXS6FXA1_BTU` |
| Vendor ZIP | `A528BXXS6FXA1_vendor.zip` |
| Vendor ZIP SHA256 | `dfc8acf78196d21287f137aa07e378cf9df0c6c55805fff1a81ec0c1dc0d3c43` |
| Vendor image | `vendor.img` ext4, 1.593.212.928 bytes descompactados |

A device tree importada em `device/samsung/a52sxq/proprietary-files.txt` é a referência de arquivos exigidos pelo build Android. O `vendor.img` baixado pelo workflow é uma entrada binária de runtime, não um substituto para os makefiles de vendor nem para a árvore Android/HyperOS.

Os componentes nativos do A52s têm precedência para câmera, áudio, display/HWC, sensores, fingerprint, RIL/modem, Wi-Fi, Bluetooth, NFC e carregamento. O userspace HyperOS não deve substituir essas bibliotecas sem uma hipótese de compatibilidade documentada e um teste correspondente.

Fonte: [Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq](https://github.com/Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq).
