# Segundo teste full com donor ZIP — 2026-08-20

O run manual [32390265902](https://github.com/vinisg61-coder/xiaomi-hyperos-a52sxq/actions/runs/32390265902) executou `Prepare/build a52sxq (full)` com `DONOR=lisa`, `ANDROID_VERSION=15`, `HYPEROS_VERSION=2.0` e `BUILD_VARIANT=userdebug`.

A sincronização baixou o archive HyperOS 2 donor diretamente no runner e passou as verificações de tamanho (`4338708939` bytes), SHA256 (`c84941ebece1d99101ae19ffda7f7a4ce911433c49e051d693d7de869fa46edf`) e integridade ZIP. O bloqueio ocorreu na etapa **Prepare or build**, com a mensagem:

```text
Build completo requer ANDROID_BUILD_TOP apontando para uma árvore Android/HyperOS com build/envsetup.sh.
```

Isso é esperado para este donor: `CraftyOs_China_HOTFIX.zip` contém imagens pré-compiladas (`boot.img`, `dtbo.img`, `logo.img`, `super.img.zst`) e metadados de recovery, não uma árvore de código Android/HyperOS com `build/envsetup.sh`. O pipeline não pode tratar `super.img.zst` como source tree nem transformar o `boot.img`/`dtbo.img` do Redmi Note 10 Pro em imagens do Samsung A52s.

O run, portanto, comprova a aquisição e validação do donor, mas não produz ROM A52s, não produz imagens de build nativas e não confirma boot. Para o modo full continuar, falta uma árvore Android/HyperOS 2 baseada em Android 15 com build system, além dos blobs/vendor/firmware nativos do `a52sxq` e de um kernel/DTB/DTBO Samsung compatível.
