#!/usr/bin/env bash
# VERIS site dogrulayici.
#   Kullanim:  bash verify.sh https://canlisecim.com
#   Bu betik kendi imzasiyla (verify.sh.sig) dagitilir; calistirmadan once okuyun ve imzayi dogrulayin.
set -uo pipefail
URL="${1:-}"
[ -z "$URL" ] && { echo "Kullanim: verify.sh <url>"; exit 2; }
ID="ahmethan@ahmethankalenderoglu.com"
NS="veris-site"
PUB='ahmethan@ahmethankalenderoglu.com namespaces="veris-site" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJCMfaekdASPC4xyir4xR9MCjMWW1rsZEcEjT7BH3Kj'
hash_stdin(){ if command -v sha256sum >/dev/null 2>&1; then sha256sum|cut -d' ' -f1; else shasum -a 256|cut -d' ' -f1; fi; }
for t in curl ssh-keygen sed awk; do command -v "$t" >/dev/null 2>&1 || { echo "eksik arac: $t"; exit 3; }; done
if [ -t 1 ]; then RED=$'\033[1;31m'; GRN=$'\033[1;32m'; DIM=$'\033[2m'; RST=$'\033[0m'; else RED=; GRN=; DIM=; RST=; fi
fail(){ printf '%sX  DOGRULANAMADI%s -> %s\n' "$RED" "$RST" "$1"; exit 1; }
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT; cd "$d" || exit 3
COPTS=(-fsSL)
case "$URL" in *.onion|*.onion/*|*.onion:*) COPTS+=(--socks5-hostname "${TOR_PROXY:-127.0.0.1:9050}");; esac
curl "${COPTS[@]}" "$URL" -o page.html || fail "sayfa indirilemedi: $URL (.onion ise Tor calisiyor mu? SOCKS 127.0.0.1:9050)"
grep -q '^<!-- VERIS-SIGNATURE' page.html || fail "bu sayfada imza yok: $URL"
sed '/^<!-- VERIS-SIGNATURE/,$d' page.html > content.txt
H=$(hash_stdin < content.txt)
# imza alanlarini SADECE marker sonrasi gercek bloktan al (govde metni "content-sha256:" gecebilir)
sed -n '/^<!-- VERIS-SIGNATURE/,$p' page.html > sigblock.txt
INPAGE=$(grep -m1 'content-sha256:' sigblock.txt | awk '{print $2}')
if [ "$H" != "$INPAGE" ] && grep -q '/cdn-cgi/l/email-protection' content.txt; then
  fail "icerik hash'i tutmuyor: Cloudflare 'Email Address Obfuscation' sayfadaki e-posta adresini degistiriyor. Imza bozulmamis olabilir; site sahibinin bu ozelligi kapatmasi gerekir. sayfadaki=$INPAGE bulunan=$H"
fi
[ "$H" = "$INPAGE" ] || fail "icerik hash'i tutmuyor (sayfa degistirilmis ya da bir proxy/Cloudflare araya giriyor). sayfadaki=$INPAGE bulunan=$H"
sed -n '/-----BEGIN SSH SIGNATURE-----/,/-----END SSH SIGNATURE-----/p' sigblock.txt > sig
printf '%s\n' "$PUB" > allowed_signers
printf %s "$H" | ssh-keygen -Y verify -f allowed_signers -I "$ID" -n "$NS" -s sig >/dev/null 2>&1 || fail "imza gecersiz - sayfa bana ait degil."
printf '%sOK  DOGRULANDI%s -> %s tarafimca imzalanmis (gecerli imza).\n' "$GRN" "$RST" "$URL"
printf '%sNot: Bu hizli yontem, bu site ele gecirilmisse yaniltici olabilir; tam guvenlik icin\n     rehberdeki manuel adimlari kendi araclarinizla yapin: https://ahmethankalenderoglu.com/dogrulama%s\n' "$DIM" "$RST"
