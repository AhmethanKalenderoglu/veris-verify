# veris-verify

[![tests](https://github.com/AhmethanKalenderoglu/veris-verify/actions/workflows/ci.yml/badge.svg)](https://github.com/AhmethanKalenderoglu/veris-verify/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

*[English below](#english)*

VERIS projesine ait sitelerin (ahmethankalenderoglu.com, veris.vote, canlisecim.com, api.canlisecim.com) imzasını doğrulayan betik.

> **Geçici durum (Ekim 2026):** Clearnet adresleri Cloudflare üzerinden sunulduğu için Cloudflare sayfalara kendi
> kodunu ekleyebiliyor ve doğrulama `hash'i tutmuyor` hatası verebiliyor. Bu, imzaların bozulduğu anlamına gelmez.
> Şimdilik doğrulamayı [rehberdeki](https://ahmethankalenderoglu.com/dogrulama) **.onion adresleri** üzerinden yapın.

Betik **kendi imzasıyla** dağıtılır. Doğrudan `curl | bash` ile çalıştırmayın; önce indirin, okuyun, imzasını doğrulayın.

## Kullanım

```bash
# 1. İndir
curl -fsSLO https://raw.githubusercontent.com/AhmethanKalenderoglu/veris-verify/main/verify.sh
curl -fsSLO https://raw.githubusercontent.com/AhmethanKalenderoglu/veris-verify/main/verify.sh.sig
curl -fsSLO https://raw.githubusercontent.com/AhmethanKalenderoglu/veris-verify/main/allowed_signers

# 2. Betiğin imzasını doğrula  ("Good" çıktısı beklenir)
ssh-keygen -Y verify -f allowed_signers -I ahmethan@ahmethankalenderoglu.com -n veris-verify -s verify.sh.sig < verify.sh

# 3. Oku, sonra çalıştır
bash verify.sh https://veris.vote
```

Gerekenler: `curl`, `ssh-keygen` (OpenSSH 8.0+), `sha256sum` veya `shasum`. Windows'ta Git Bash önerilir. `.onion` adresleri için Tor SOCKS (127.0.0.1:9050) açık olmalıdır.

## Anahtarı bağımsız teyit edin

Bu depodaki `allowed_signers` ile aynı depodan gelen imza tek başına güven vermez. Açık anahtarın parmak izini başka bir kanaldan karşılaştırın:

```
SHA256:Bsm2osevqT9KjFlaeqwNvaz7LqNCTDMqqveFLG5BmII
```

- https://ahmethankalenderoglu.com/pubkey.txt
- .onion: http://ak62q5nhzxxuixpjvmtbfdumaagi2yqbsgbhvf55lhftkst5bqsizgqd.onion/pubkey.txt
- Rehber: https://ahmethankalenderoglu.com/dogrulama

`verify.sh` SHA-256: `a2007345b56bbbea3f69b65625b83516542628f66181ebfa288097de24e6bc9b`

## Testler

```bash
bash tests/run.sh
```

Testler geçici bir anahtarla örnek sayfalar imzalar; gerçek imza anahtarı kullanılmaz. Kapsanan durumlar:
geçerli imza, değiştirilmiş içerik, imzasız sayfa, başka anahtarla imza, yanlış namespace, gövdede sahte
`content-sha256` satırı, Cloudflare e-posta gizleme, `.onion` adreslerinin (port'lu olanlar dahil) Tor
üzerinden indirilmesi. CI ayrıca ShellCheck çalıştırır ve `verify.sh` imzasını doğrular.

## Lisans

[MIT](LICENSE)

---

## English

`verify.sh` checks that a page on one of the VERIS project sites (ahmethankalenderoglu.com, veris.vote,
canlisecim.com, api.canlisecim.com) carries a valid signature from the project's Ed25519 key.

Every signed page ends with a `VERIS-SIGNATURE` block. The script hashes everything above that block with
SHA-256, compares it with the `content-sha256` value in the block, and verifies the SSH signature over that
hash (namespace `veris-site`) against the pinned public key.

> **Temporary notice (October 2026):** the clearnet sites are served through Cloudflare, which can inject its own
> code into pages, so verification may fail with a hash mismatch. The signatures themselves are intact. For now, verify
> through the **.onion addresses** listed in the [guide](https://ahmethankalenderoglu.com/dogrulama).

The script is distributed with its own signature. Do not pipe it into `bash`: download it, read it, verify it.

```bash
curl -fsSLO https://raw.githubusercontent.com/AhmethanKalenderoglu/veris-verify/main/verify.sh
curl -fsSLO https://raw.githubusercontent.com/AhmethanKalenderoglu/veris-verify/main/verify.sh.sig
curl -fsSLO https://raw.githubusercontent.com/AhmethanKalenderoglu/veris-verify/main/allowed_signers

# expect "Good"
ssh-keygen -Y verify -f allowed_signers -I ahmethan@ahmethankalenderoglu.com -n veris-verify -s verify.sh.sig < verify.sh

bash verify.sh https://veris.vote
```

Requirements: `curl`, `ssh-keygen` (OpenSSH 8.0+), `sha256sum` or `shasum`. On Windows, use Git Bash.
`.onion` addresses need a Tor SOCKS proxy on 127.0.0.1:9050 (override with `TOR_PROXY`).

A signature that comes from the same repository as `allowed_signers` proves nothing by itself. Compare the key
fingerprint `SHA256:Bsm2osevqT9KjFlaeqwNvaz7LqNCTDMqqveFLG5BmII` through an independent channel, such as
https://ahmethankalenderoglu.com/pubkey.txt or its `.onion` mirror listed above.

Run the tests with `bash tests/run.sh`. License: MIT.
