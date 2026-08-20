# Fontes confirmadas para o port A52s

## Device tree

- `Alone0316/android_device_samsung_a52sxq`, commit `eb08adf5d14297a45448a34a2aa6bf81674c2b86`.
- O tree contém `AndroidProducts.mk`, `BoardConfig.mk`, `device.mk`, `proprietary-files.txt`, scripts de extração, `libinit`, rootdir, fstab, overlays e sepolicy específicos do `a52sxq`.
- URL: https://github.com/Alone0316/android_device_samsung_a52sxq

## Kernel

- `Alone0316/android_kernel_samsung_sm7325`, branch `sep-13.1/stock`, com DTBs em `arch/arm64/boot/dts/samsung/a52/a52sxq` e defconfigs `vendor/a52sxq_eur_open_defconfig` e `vendor/a52sxq_kor_single_defconfig`.
- URL: https://github.com/Alone0316/android_kernel_samsung_sm7325
- Alternativa mais recente: `bone-machine/android_kernel_samsung_sm7325_a52s_5g`, Linux 5.4.289, com suporte declarado para AOSP e One UI e build scripts para A52s.
- URL: https://github.com/bone-machine/android_kernel_samsung_sm7325_a52s_5g

## Vendor e firmware

- `Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq` contém binários de firmware/modem/bootloader do Galaxy A52s e aponta releases por CSC/OMC.
- URL: https://github.com/Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq
- SamFw lista firmware oficial do SM-A528B. A listagem consultada mostra firmware `A528BXXSBGYI4`, revisão B, patch de segurança 2025-09-01 e OS/One UI Android 14; não há uma base oficial Android 15 do A52s confirmada na página consultada.
- URL: https://samfw.com/firmware/SM-A528B

## Target legado UN1CA

- `/home/ubuntu/UN1CA/target/a52sxq` tem 132 arquivos e aproximadamente 71 MiB, principalmente patches e firmware Qualcomm WLAN `wpss`; inclui `config.sh`, `installer`, `vintf`, overlays e patches de vendor.
- Isso é material nativo de suporte ao A52s, não uma árvore HyperOS nem uma ROM Android 15 completa.

## Consequência para o port

O kernel, DTB/DTBO, vendor, firmware e sepolicy do port devem vir do A52s. O donor HyperOS 2.0.215 validado contém somente imagens pré-compiladas do Redmi Note 10 Pro/Max e pode fornecer userspace para investigação, mas não pode fornecer kernel, vendor ou boot para o Samsung.
