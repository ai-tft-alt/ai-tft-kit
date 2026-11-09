"""hwp.py — 한글(HWP/HWPX) 문서를 텍스트로 읽는 작은 명령줄 도구 (AI-TFT 키트).

사용법
  python hwp.py text  <파일.hwp|파일.hwpx> [--out 결과.txt]   본문 텍스트 출력
  python hwp.py info  <파일>                                   쪽수 · 글자 수 · 읽은 방법
  python hwp.py check                                          이 PC에서 쓸 수 있는 방법 확인

읽는 방법 (자동 선택)
  .hwpx : 압축을 풀어 본문 XML을 직접 읽음 (추가 설치 없음)
  .hwp  : ① 한컴오피스(한글)가 설치돼 있으면 한글 자동화(COM)로 텍스트 저장
          ② 없으면 pyhwp(hwp5txt)가 설치돼 있으면 그것으로 추출
문서 내용은 PC 밖으로 보내지 않습니다.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from xml.etree import ElementTree as ET

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


def read_hwpx(path):
    paras = []
    with zipfile.ZipFile(path) as z:
        names = sorted(n for n in z.namelist() if re.match(r"Contents/section\d+\.xml$", n))
        for n in names:
            root = ET.fromstring(z.read(n))
            for p in root.iter():
                if p.tag.endswith("}p"):
                    texts = [t.text or "" for t in p.iter() if t.tag.endswith("}t")]
                    line = "".join(texts).strip()
                    if line:
                        paras.append(line)
    return "\n".join(paras), "hwpx-xml"


def has_hancom():
    if os.name != "nt":
        return False
    try:
        import win32com.client  # noqa: F401
        return True
    except Exception:
        pass
    # pywin32가 없으면 PowerShell로 COM 확인
    r = subprocess.run(["powershell", "-NoProfile", "-Command",
                        "try{$h=New-Object -ComObject HWPFrame.HwpObject;$h.Quit();'ok'}catch{'no'}"],
                       capture_output=True, text=True)
    return "ok" in r.stdout


def read_hwp_hancom(path):
    """한글 자동화(COM)로 .hwp → .txt(UTF-8) 저장 후 읽기. PowerShell을 써서 pywin32 없이 동작."""
    src = os.path.abspath(path)
    tmpdir = tempfile.mkdtemp(prefix="hwpcli_")
    out = os.path.join(tmpdir, "out.txt")
    ps = (
        "$h=New-Object -ComObject HWPFrame.HwpObject;"
        "$h.XHwpWindows.Item(0).Visible=$false;"
        "$h.RegisterModule('FilePathCheckDLL','FilePathCheckerModule')|Out-Null;"
        f"$null=$h.Open('{src}','HWP','forceopen:true');"
        f"$null=$h.SaveAs('{out}','UNICODE','');"
        "$h.Clear(1);$h.Quit()"
    )
    r = subprocess.run(["powershell", "-NoProfile", "-Command", ps], capture_output=True, text=True)
    if not os.path.exists(out):
        raise RuntimeError("한글 자동화로 변환하지 못했습니다: " + (r.stderr or r.stdout).strip()[:300])
    with open(out, "rb") as f:
        raw = f.read()
    shutil.rmtree(tmpdir, ignore_errors=True)
    for enc in ("utf-16", "utf-8-sig", "cp949"):
        try:
            text = raw.decode(enc)
            break
        except Exception:
            continue
    lines = [l.rstrip() for l in text.replace("\r\n", "\n").split("\n")]
    return "\n".join(l for l in lines if l.strip()), "hancom-com"


def read_hwp_pyhwp(path):
    exe = shutil.which("hwp5txt")
    if not exe:
        raise RuntimeError("pyhwp(hwp5txt)가 없습니다")
    r = subprocess.run([exe, path], capture_output=True)
    return r.stdout.decode("utf-8", "replace"), "pyhwp"


def read_any(path):
    ext = os.path.splitext(path)[1].lower()
    if ext == ".hwpx":
        return read_hwpx(path)
    if ext == ".hwp":
        errors = []
        if has_hancom():
            try:
                return read_hwp_hancom(path)
            except Exception as e:
                errors.append(str(e))
        try:
            return read_hwp_pyhwp(path)
        except Exception as e:
            errors.append(str(e))
        raise SystemExit("HWP를 읽을 방법이 없습니다. 한글(한컴오피스)을 설치하거나 `pip install pyhwp` 하세요.\n"
                         + "\n".join(errors))
    raise SystemExit(f"지원하지 않는 형식입니다: {ext} (.hwp, .hwpx 만)")


def main():
    ap = argparse.ArgumentParser(description="한글(HWP/HWPX) 문서 텍스트 추출")
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("text"); t.add_argument("file"); t.add_argument("--out")
    i = sub.add_parser("info"); i.add_argument("file")
    sub.add_parser("check")
    a = ap.parse_args()

    if a.cmd == "check":
        print("hwpx 읽기      : 가능 (추가 설치 없음)")
        print("hwp - 한글 자동화:", "가능" if has_hancom() else "없음 (한컴오피스 미설치)")
        print("hwp - pyhwp     :", "가능" if shutil.which("hwp5txt") else "없음 (pip install pyhwp)")
        return
    if not os.path.exists(a.file):
        raise SystemExit(f"파일이 없습니다: {a.file}")
    text, how = read_any(a.file)
    if a.cmd == "info":
        print(f"파일: {a.file}\n읽은 방법: {how}\n문단 수: {len(text.splitlines())}\n글자 수: {len(text)}")
        return
    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"저장: {a.out} ({len(text)}자, {how})")
    else:
        print(text)


if __name__ == "__main__":
    main()
