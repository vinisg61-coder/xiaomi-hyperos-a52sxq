# Kernel nativo do Samsung Galaxy A52s (`a52sxq`)

O port mantém o kernel e as imagens de boot do A52s; o kernel do donor Xiaomi nunca é reutilizado. A release pública usada no estágio atual é `A528BXXS6FXA1_BTU`.

| Artefato | SHA256 |
| --- | --- |
| `A528BXXS6FXA1_kernel.tar` | `9175331267f196a19f6d1cf9cc489150ed615396af0e8aeb51972be08336eb04` |
| `boot.img` extraído | `8f5b117245305eba99ab49e5283086bf1a1575199f111c0e13c1be87bf1f2f66` |
| `dtbo.img` extraído | `2a5c4825c3b6c8d2bc4392e00d8683d94f1c3b1c1ff2a993c20875da12243ed1` |
| `vendor_boot.img` extraído | `9102d438e0bce9e2f256dab0fe8d00f9ee44878fa845c0737ba5867d9cf63c2e` |
| `vbmeta.img` extraído | `b8ad181342421413113b1aedc8d034984727a1eacdac5a4319c405cc995bd22f` |

A árvore de kernel de referência é `Alone0316/android_kernel_samsung_sm7325`, branch `sep-13.1/stock`, com DTBs em `arch/arm64/boot/dts/samsung/a52/a52sxq` e defconfigs `vendor/a52sxq_eur_open_defconfig`/`vendor/a52sxq_kor_single_defconfig`. Uma alternativa mais recente é `bone-machine/android_kernel_samsung_sm7325_a52s_5g`, baseada em Linux 5.4.289.

Fonte de imagens: [Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq](https://github.com/Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq).
