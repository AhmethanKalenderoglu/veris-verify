#!/usr/bin/env bash
# verify.sh testleri.
#   Kullanim:  bash tests/run.sh
# Gecici bir test anahtariyla ornek sayfalar imzalanir ve verify.sh'in, PUB satiri bu
# anahtarla degistirilmis bir kopyasi uzerinde calistirilir. Gercek anahtar kullanilmaz.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ID="ahmethan@ahmethankalenderoglu.com"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

hash_stdin(){ if command -v sha256sum >/dev/null 2>&1; then sha256sum|cut -d' ' -f1; else shasum -a 256|cut -d' ' -f1; fi; }
file_url(){ if command -v cygpath >/dev/null 2>&1; then printf 'file:///%s' "$(cygpath -m "$1")"; else printf 'file://%s' "$1"; fi; }

ssh-keygen -q -t ed25519 -N "" -C test -f "$T/key"
ssh-keygen -q -t ed25519 -N "" -C test -f "$T/other"
sed "s|^PUB=.*|PUB='$ID namespaces=\"veris-site\" $(cut -d' ' -f1,2 "$T/key.pub")'|" "$ROOT/verify.sh" > "$T/verify.sh"

# sign <icerik_dosyasi> <cikti> [anahtar] [namespace]
sign(){
  local key=${3:-$T/key} ns=${4:-veris-site} h
  h=$(hash_stdin < "$1")
  printf %s "$h" > "$T/h"
  rm -f "$T/h.sig"
  ssh-keygen -q -Y sign -f "$key" -n "$ns" "$T/h" 2>/dev/null
  { cat "$1"
    printf '<!-- VERIS-SIGNATURE v1\nnamespace: %s\ncontent-sha256: %s\n' "$ns" "$h"
    cat "$T/h.sig"
    printf -- '-->\n'; } > "$2"
}

PASS=0; FAIL=0
# check <ad> <beklenen_cikis_kodu> <ciktida_aranacak> <url>
check(){
  local out code
  out=$(bash "$T/verify.sh" "$4" 2>&1); code=$?
  if [ "$code" = "$2" ] && grep -q -- "$3" <<<"$out"; then
    PASS=$((PASS+1)); printf 'ok   %s\n' "$1"
  else
    FAIL=$((FAIL+1)); printf 'FAIL %s (cikis=%s)\n%s\n' "$1" "$code" "$out"
  fi
}

cat > "$T/body.html" <<'EOF'
<!doctype html>
<html><body>
<p>VERIS test sayfasi</p>
<p>E-posta: <a href="mailto:ahmethan@ahmethankalenderoglu.com">ahmethan@ahmethankalenderoglu.com</a></p>
</body></html>
EOF

sign "$T/body.html" "$T/valid.html"
check "gecerli imza" 0 "DOGRULANDI" "$(file_url "$T/valid.html")"

sed 's/test sayfasi/degistirilmis sayfa/' "$T/valid.html" > "$T/tampered.html"
check "degistirilmis icerik" 1 "hash'i tutmuyor" "$(file_url "$T/tampered.html")"

check "imzasiz sayfa" 1 "imza yok" "$(file_url "$T/body.html")"

sign "$T/body.html" "$T/other.html" "$T/other"
check "baska anahtarla imza" 1 "imza gecersiz" "$(file_url "$T/other.html")"

sign "$T/body.html" "$T/ns.html" "$T/key" "veris-verify"
check "yanlis namespace" 1 "imza gecersiz" "$(file_url "$T/ns.html")"

{ head -3 "$T/body.html"; printf '<p>content-sha256: %064d</p>\n' 0; tail -n +4 "$T/body.html"; } > "$T/decoy_body.html"
sign "$T/decoy_body.html" "$T/decoy.html"
check "govdede sahte content-sha256 satiri" 0 "DOGRULANDI" "$(file_url "$T/decoy.html")"

sed 's|<a href="mailto:[^"]*">[^<]*</a>|<a href="/cdn-cgi/l/email-protection#00">[email\&#160;protected]</a>|' "$T/valid.html" > "$T/cloudflare.html"
check "Cloudflare e-posta gizleme" 1 "Email Address Obfuscation" "$(file_url "$T/cloudflare.html")"

check "arguman yok" 2 "Kullanim" ""

for u in "http://example.onion" "http://example.onion/a" "http://example.onion:80/"; do
  trace=$(TOR_PROXY=127.0.0.1:9 bash -x "$T/verify.sh" "$u" 2>&1)
  if grep -q -- "--socks5-hostname 127.0.0.1:9" <<<"$trace"; then
    PASS=$((PASS+1)); printf 'ok   Tor uzerinden: %s\n' "$u"
  else
    FAIL=$((FAIL+1)); printf 'FAIL Tor uzerinden gitmedi: %s\n' "$u"
  fi
done

printf '\n%d gecti, %d kaldi\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
