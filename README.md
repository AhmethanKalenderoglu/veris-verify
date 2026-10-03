# veris-verify

VERIS projesine ait sitelerin (ahmethankalenderoglu.com, veris.vote, canlisecim.com, api.canlisecim.com) imzasını doğrulayan betik.

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

`verify.sh` SHA-256: `cb85cc5c8a57d7b264922879cfae69b9c030d86759a42ed5376f57009d5351be`
