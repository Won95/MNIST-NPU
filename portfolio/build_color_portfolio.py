#!/usr/bin/env python3
# Build a color-evidence technical portfolio from original OpenROAD PNGs.
# All image files are inserted unchanged; no grayscale/color filters are applied.
from pathlib import Path
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from PIL import Image
import argparse

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "physical_design/reports/nangate45/mnist_npu/exp_arith_tree_ks"
OUT = ROOT / "portfolio/output"
COL = {
    "text": RGBColor(22, 34, 46),
    "gray": RGBColor(78, 94, 108),
    "line": RGBColor(198, 209, 215),
    "accent": RGBColor(0, 128, 156),
    "pale": RGBColor(235, 245, 248),
    "white": RGBColor(255, 255, 255),
    "navy": RGBColor(16, 34, 49),
}
PICS = {
    "placement": "final_placement.webp.png",
    "cts": "cts_default_MAIN_CLOCK_layout.webp.png",
    "cts_tree": "cts_default_MAIN_CLOCK.webp.png",
    "routing": "final_routing.webp.png",
    "congestion": "final_congestion.webp.png",
    "irdrop": "final_ir_drop.webp.png",
    "worst": "final_worst_path.webp.png",
}
FONT = "NanumGothic"
prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)

def shape(slide, x, y, w, h, color=None, line=None, radius=False):
    typ = MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE
    sh = slide.shapes.add_shape(typ, Inches(x), Inches(y), Inches(w), Inches(h))
    sh.fill.solid()
    sh.fill.fore_color.rgb = color or COL["white"]
    if line:
        sh.line.color.rgb = line
        sh.line.width = Pt(0.65)
    else:
        sh.line.fill.background()
    if radius:
        try: sh.adjustments[0] = 0.1
        except Exception: pass
    return sh

def text(slide, value, x, y, w, h, size=14, bold=False, color="text", align=None, margin=0, font=None):
    tx = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tx.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = Inches(margin)
    tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    lines = str(value).split("\n")
    for idx, line in enumerate(lines):
        p = tf.paragraphs[0] if idx == 0 else tf.add_paragraph()
        p.text = line
        p.alignment = align or PP_ALIGN.LEFT
        p.space_after = Pt(3)
        p.font.name = font or FONT
        p.font.size = Pt(size)
        p.font.bold = bold
        p.font.color.rgb = COL[color] if isinstance(color, str) else color
    return tx

def photo(slide, key, x, y, w, h, caption=None):
    path = SRC / PICS[key]
    if not path.is_file():
        raise FileNotFoundError("Original PnR image missing: " + str(path))
    with Image.open(path) as im:
        im.verify()
    with Image.open(path) as im:
        wi, he = im.size
    scale = min(w / wi, h / he)
    pw, ph = wi * scale, he * scale
    left, top = x + (w-pw)/2, y + (h-ph)/2
    shape(slide, x, y, w, h, COL["navy"])
    slide.shapes.add_picture(str(path), Inches(left), Inches(top),
                             width=Inches(pw), height=Inches(ph))
    if caption:
        text(slide, caption, x, y+h+0.06, w, 0.26, 10, color="gray",
             align=PP_ALIGN.CENTER)

def base(kicker, title, number):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    shape(slide, 0, 0, 13.333, 7.5)
    text(slide, kicker, 0.66, 0.32, 8.6, 0.23, 11, bold=True, color="accent")
    text(slide, "ENGINEERING PORTFOLIO / MNIST-NPU", 9.5, 0.34, 3.2, 0.2, 8.5, color="gray", align=PP_ALIGN.RIGHT)
    shape(slide, 0.66, 0.70, 12.0, 0.016, COL["line"])
    text(slide, title, 0.66, 0.90, 12.0, 0.56, 25, bold=True)
    shape(slide, 0.66, 7.14, 12.0, 0.015, COL["line"])
    text(slide, "Nangate45 · OpenROAD · exp_arith_tree_ks", 0.66, 7.20, 8.1, 0.16, 8.5, color="gray")
    text(slide, f"{number:02d} / 13", 11.78, 7.20, 0.88, 0.16, 8.5, color="gray", align=PP_ALIGN.RIGHT)
    return slide

def metric(slide, value, label, x, y, w):
    shape(slide, x, y, w, 0.88, COL["pale"])
    shape(slide, x, y, w, 0.035, COL["accent"])
    text(slide, value, x+0.13, y+0.13, w-0.25, 0.34, 22, bold=True)
    text(slide, label, x+0.13, y+0.55, w-0.25, 0.20, 10, color="gray")

def box(slide, title, bullets, x, y, w, h, size=13):
    shape(slide, x, y, w, h, COL["pale"])
    text(slide, title, x+0.22, y+0.18, w-0.44, 0.35, 15, bold=True)
    top = y + 0.62
    for b in bullets:
        text(slide, "•  "+b, x+0.22, top, w-0.45, 0.46, size, color="text")
        top += 0.59

def row_table(slide, head, rows, x, y, widths, row_h=0.53, fs=12):
    xx = x
    for label, wd in zip(head, widths):
        shape(slide, xx, y, wd, row_h, COL["navy"])
        text(slide, label, xx+0.10, y+0.1, wd-0.2, row_h-0.2, fs-1, bold=True, color="white")
        xx += wd
    y += row_h
    for ri, row in enumerate(rows):
        xx = x
        bg = COL["pale"] if ri % 2 else COL["white"]
        for v, wd in zip(row, widths):
            shape(slide, xx, y, wd, row_h, bg, COL["line"])
            text(slide, str(v), xx+0.10, y+0.10, wd-0.2, row_h-0.2, fs, bold=(ri==len(rows)-1))
            xx += wd
        y += row_h

def flow(slide, parts, x, y, total_w, box_h=0.78):
    gap = 0.25
    bw = (total_w-gap*(len(parts)-1))/len(parts)
    for i,(title,sub) in enumerate(parts):
        xx=x+i*(bw+gap)
        shape(slide,xx,y,bw,box_h,COL["pale"],COL["line"])
        shape(slide,xx,y,bw,0.035,COL["accent"])
        text(slide,title,xx+0.08,y+0.12,bw-0.16,0.25,14,bold=True,align=PP_ALIGN.CENTER)
        text(slide,sub,xx+0.08,y+0.46,bw-0.16,0.18,10,color="gray",align=PP_ALIGN.CENTER)
        if i<len(parts)-1:
            text(slide,"→",xx+bw+0.025,y+0.25,gap-0.05,0.23,15,bold=True,color="accent",
                 align=PP_ALIGN.CENTER)

# 01 Cover
s=prs.slides.add_slide(prs.slide_layouts[6])
shape(s,0,0,13.333,7.5,COL["navy"])
text(s,"PHYSICAL DESIGN / RTL-TO-GDSII",0.7,0.4,7.5,0.3,14,bold=True,color="white")
text(s,"8-PE MNIST NPU",0.7,1.25,6.55,0.82,42,bold=True,color="white")
text(s,"5 ns 타이밍 클로저 및 산술 합성 최적화",0.7,2.13,6.1,0.55,21,bold=True,color=RGBColor(137,226,237))
text(s,"7개의 Hard SRAM을 통합하여 배치배선을 수행하였음.\n합성 옵션별 Post-route 결과를 비교하여 최종 구현안을 선정하였음.",0.7,2.88,5.7,1.25,15,color="white")
for i, (v,n) in enumerate([("5.0 ns","목표 클록"),("72,005 µm²","표준셀 면적"),("+0.801 ns","Setup WNS")]):
    x=0.7+i*2.05
    shape(s,x,4.65,1.9,1.0,RGBColor(32,59,74))
    text(s,v,x+0.10,4.80,1.7,0.34,18,bold=True,color="white")
    text(s,n,x+0.10,5.20,1.7,0.24,10,color="white")
photo(s,"irdrop",7.1,0.85,5.5,5.85)
text(s,"원본: exp_arith_tree_ks / IR-drop",7.2,6.75,5.2,0.22,10,color="white",align=PP_ALIGN.RIGHT)
text(s,"github.com/Won95/MNIST-NPU",0.7,6.9,6.0,0.24,11,color="white")

# 02 Overview
s=base("01 / PROJECT OVERVIEW","5 ns 타이밍 제약을 목표로 물리적 구현을 비교하였음",2)
text(s,"단순 RTL 합성을 넘어서, Hard SRAM을 포함한 P&R 및 Post-route 타이밍을 분석하였음.",0.66,1.63,11.9,0.35,14,color="gray")
for i,(v,n) in enumerate([("784→32→10","MLP"),("8","PE 수"),("7","SRAM Macro"),("200 MHz","Target Clock")]):
    metric(s,v,n,0.7+i*3.05,2.22,2.86)
row_table(s,["조건","설계 기준"],[
    ("Technology","Nangate45 typical"),("Clock","5.0 ns / 200 MHz"),
    ("I/O Delay","최대 1.0 ns / Virtual Clock"),("Uncertainty","Setup 0.20 ns / Hold 0.10 ns"),
    ("Floorplan","Utilization 60% / AR 1.2"),("SRAM","7 × 512×64 / LEF + LIB")],
    0.7,3.45,[3.3,8.5],0.45,12)

# 03 Architecture
s=base("02 / SYSTEM ARCHITECTURE","동일한 8-PE MAC 배열을 두 계층에서 재사용하였음",3)
text(s,"FC1은 네 그룹, FC2는 두 그룹으로 나누어 PE를 재사용하였음.",0.66,1.64,11.7,0.34,14,color="gray")
text(s,"FC1 · 784 → 32",0.75,2.15,4.0,0.3,16,bold=True)
flow(s,[("Input Buffer","784 × INT8"),("8-PE MAC","4 groups"),("ReLU / Shift","INT8 quant."),("FC1 Output","32 × INT8")],0.75,2.58,11.5)
text(s,"FC2 · 32 → 10",0.75,3.78,4.0,0.3,16,bold=True)
flow(s,[("FC1 Output","32 × INT8"),("Same 8-PE","2 groups"),("Score Regs","10 × INT32"),("Argmax Tree","Digit[3:0]")],0.75,4.21,11.5)
box(s,"PE 연산",["Signed INT8 × Signed INT8 곱셈을 수행하였음.","Signed INT32 Accumulator를 사용하였음."],0.75,5.45,5.5,1.35,11)
box(s,"SRAM 인터페이스",["7개 fakeram45_512x64 Macro를 사용하였음.","64-bit Word를 8개의 Weight Lane으로 분할하였음."],6.55,5.45,5.7,1.35,11)

# 04 Functional test
s=base("03 / VERIFICATION","100개 MNIST 샘플에서 Python 모델과 일치하였음",4)
for i,(v,n) in enumerate([("100 / 100","입력 검증"),("0","RTL–Python mismatch"),("98%","분류 정확도"),("PASS","SRAM Write")]):
    metric(s,v,n,0.7+i*3.05,1.72,2.86)
box(s,"기능 검증 대상",[
    "SRAM Bank 대표 쓰기 데이터를 검사하였음.",
    "이미지별 784개 입력 픽셀을 검증하였음.",
    "FC1 32개, FC2 10개 값을 Python 결과와 비교하였음.",
    "최종 Digit를 Python Golden Model과 비교하였음."],0.75,3.0,6.1,3.55,12)
shape(s,7.05,3.0,5.2,3.55,COL["navy"])
text(s,"simulation.log / 실제 기록",7.30,3.23,4.7,0.33,14,bold=True,color="white")
log="[PASS] SRAM Write Verification\nImage Load: 100/100 images\nRTL_correct=98 / Python_correct=98\nmismatches=0\n[PASS] RTL equals Python golden model"
text(s,log,7.30,3.84,4.7,1.85,13,color="white",font="DejaVu Sans Mono")
text(s,"※ 100개 샘플 기록이며 Formal LEC 결과는 아님.",7.29,6.08,4.7,0.23,10,color="white")

# 05 Argmax
s=base("04 / RTL OPTIMIZATION","Argmax의 비교 의존 깊이를 9단에서 4단으로 줄였음",5)
text(s,"10개 FC2 Score 중 최대값을 선택하는 Comparator Tree를 구현하였음.",0.75,1.72,11.2,0.35,14,color="gray")
box(s,"기존 직렬 비교",["9개의 비교기가 순차적으로 연결되었음.","최장 의존 깊이가 9단계였음."],0.75,2.4,5.65,2.1,13)
box(s,"Balanced Comparator Tree",["5 → 2 → 1 → 1 구성으로 9개 비교를 유지하였음.","최장 의존 깊이는 4단계로 감소하였음."],6.65,2.4,5.65,2.1,13)
shape(s,0.75,5.07,11.55,0.85,COL["pale"])
text(s,"Serial depth = 9     →     Comparator Tree depth = 4",1.18,5.27,10.6,0.3,20,bold=True,align=PP_ALIGN.CENTER)
text(s,"이 구조의 실효성은 최종 Post-route STA와 PPA 결과를 기준으로 검토하였음.",0.75,6.16,11.5,0.37,13,color="gray")

# 06 Constraints
s=base("05 / IMPLEMENTATION CONSTRAINTS","P&R 전 단계에 공통 제약을 적용하였음",6)
row_table(s,["항목","값","의미"],[
    ("Clock","5.00 ns","Setup Closure 목표"),
    ("I/O Delay","Max 1.00 ns","Virtual Clock 경로 고려"),
    ("Uncertainty","Setup 0.20 / Hold 0.10 ns","Clock Timing Margin"),
    ("Technology","Nangate45 typical","Library / Tech"),
    ("Core","Utilization 60% / AR 1.2","Floorplan"),
    ("SRAM","7 × fakeram45_512x64","Hard Macro / LEF + LIB"),
    ("CAP_MARGIN","25","Sizing 및 Capacitance")],
    0.70,1.85,[2.4,4.5,4.9],0.59,12)

# 07 Placement
s=base("06 / FLOORPLAN & PLACEMENT","실제 원본 Placement 결과에서 Macro 배치를 확인하였음",7)
photo(s,"placement",0.8,1.75,6.15,4.9,"실제 OpenROAD / exp_arith_tree_ks / final_placement.webp.png")
box(s,"SRAM Macro 배치",[
    "좌측 3개 SRAM을 MY 방향으로 배치하였음.",
    "우측 4개 SRAM을 R0 방향으로 배치하였음.",
    "중앙 Routing Channel을 확보하였음.",
    "Standard-cell Placement와 Macro 간섭을 검토하였음."],
    7.24,1.80,5.1,4.62,12)

# 08 CTS
s=base("07 / CLOCK TREE SYNTHESIS","클록 분포와 CTS 결과를 원본 컬러 이미지로 확인하였음",8)
photo(s,"cts",0.8,1.76,6.05,4.84,"CTS Layout 원본 · Clock 배선 분포")
photo(s,"cts_tree",7.05,1.76,5.25,4.84,"CTS Clock Tree Latency 원본")
text(s,"CTS 이후 Clock Buffer와 Skew가 Timing에 미치는 영향을 분석하였음.",0.85,6.77,11.6,0.25,12,color="gray")

# 09 Detailed Routing
s=base("08 / DETAILED ROUTING","실제 Routing 및 Congestion 결과를 비교하였음",9)
photo(s,"routing",0.8,1.77,6.05,4.91,"최종 Routing 원본 PNG")
photo(s,"congestion",7.05,1.77,5.25,4.91,"최종 Congestion 원본 PNG")
text(s,"Router DRC 0건 / Antenna Violating Nets 0건으로 기록되었음. 별도 Signoff DRC와 구분하였음.",
     0.8,6.82,11.9,0.25,12,color="gray")

# 10 IR-drop
s=base("09 / POWER INTEGRITY","실제 컬러 IR-drop 분포와 범례를 확인하였음",10)
photo(s,"irdrop",0.8,1.74,6.55,4.97,"최종 IR-drop 원본 Heatmap · Color Scale 유지")
box(s,"전원 무결성 검토",[
    "전원망의 공간적 전압 강하 분포를 확인하였음.",
    "높은 IR-drop 영역과 Macro 위치를 비교하였음.",
    "원본 컬러 범례를 보존하였음.",
    "정량적인 Signoff PI 결과로 확대 해석하지 않았음."],
    7.65,1.82,4.66,4.60,12)

# 11 Worst Path
s=base("10 / STATIC TIMING ANALYSIS","Worst Path는 FC2 Argmax 출력에서 관찰되었음",11)
photo(s,"worst",0.8,1.74,6.55,4.98,"Worst Path 원본 GUI Overlay")
metric(s,"+0.801 ns","Setup WNS",7.64,1.9,2.20)
metric(s,"+0.001724 ns","Hold WNS",10.00,1.9,2.34)
box(s,"최악 Setup 경로",[
    "Start: FC2 Score Register였음.",
    "Logic: Argmax Comparator Tree였음.",
    "End: Digit[0] 출력이었음.",
    "Setup/Hold TNS 모두 0으로 기록되었음.",
    "약 1.7 ps Hold Margin은 추가 개선 대상임."],
    7.66,3.18,4.68,3.08,11)

# 12 PPA
s=base("11 / FINAL PPA COMPARISON","실험별 Post-route 결과로 최종 구현안을 선정하였음",12)
row_table(s,["Variant","Cell Area (µm²)","Setup WNS","Hold WNS","Power Est."],[
    ("Baseline","76,557.2","+0.6556 ns","+0.0017 ns","40.14 mW"),
    ("Booth","74,229.4","+0.5365 ns","−0.0012 ns","40.26 mW"),
    ("Arithmetic Tree","72,458.4","+0.7796 ns","+0.0039 ns","40.22 mW"),
    ("Arith. Tree + KS","72,005.1","+0.8010 ns","+0.0017 ns","40.11 mW")],
    0.70,1.83,[2.5,2.55,2.32,2.32,2.1],0.68,11.5)
metric(s,"−5.95%","Std-cell Area",0.70,5.75,3.5)
metric(s,"+145 ps","Setup Slack",4.45,5.75,3.5)
metric(s,"0","Router DRC",8.20,5.75,3.5)

# 13 Conclusion
s=base("12 / ENGINEERING CONCLUSION","Arithmetic Tree + Kogge-Stone 결과를 최종 선정하였음",13)
box(s,"확보한 성과",[
    "8-PE MAC 및 7개 SRAM Macro를 구현하였음.",
    "100-image RTL/Python 불일치 0건을 확인하였음.",
    "5 ns에서 Setup/Hold TNS 0을 기록하였음.",
    "표준셀 면적 5.95% 감소 결과를 확보하였음.",
    "실제 컬러 Placement/CTS/Routing/IR-drop/STA 이미지를 정리하였음."],
    0.75,1.85,5.85,4.62,11.5)
box(s,"추가 검증 과제",[
    "Formal LEC를 수행하지 않았음.",
    "Gate-level Simulation 증거를 확보해야 함.",
    "Standalone Signoff DRC 및 LVS가 필요함.",
    "Hold Margin 약 1.7 ps 개선이 필요함.",
    "Power Activity 및 Corner 조건 검증이 필요함."],
    6.84,1.85,5.70,4.62,11.5)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    target=OUT/"MNIST_NPU_컬러원본_기술포트폴리오.pptx"
    prs.save(target)
    print(f"Saved {len(prs.slides)} slides to {target}")
    print("Original color images:", *[str(SRC/PICS[k]) for k in PICS], sep="\n - ")

if __name__=="__main__":
    main()
