import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:student_amaliyot_app/app/app.dart';
import 'package:student_amaliyot_app/services/theme_service.dart';
import 'package:student_amaliyot_app/services/icon_service.dart';
import '../widgets/setting/setting_appbar.dart';

// ─────────────────────────────────────────────
// SVG larni to'g'ridan-to'g'ri kod ichida saqlash
// (keyinchalik assets/ papkasiga o'tkaziladi)
// ─────────────────────────────────────────────

const String _svgNightBlue = '''
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
<defs>
  <radialGradient id="nb_glow1" cx="45%" cy="40%" r="65%">
    <stop offset="0%" stop-color="#60aaff" stop-opacity="0.85"/>
    <stop offset="100%" stop-color="#001144" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="nb_glow2" cx="70%" cy="65%" r="50%">
    <stop offset="0%" stop-color="#0044cc" stop-opacity="0.6"/>
    <stop offset="100%" stop-color="#001144" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="nb_ballGrad" cx="42%" cy="36%" r="68%">
    <stop offset="0%" stop-color="#60aaff"/>
    <stop offset="45%" stop-color="#0044cc"/>
    <stop offset="100%" stop-color="#001144"/>
  </radialGradient>
  <radialGradient id="nb_glassShine" cx="38%" cy="28%" r="55%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.38"/>
    <stop offset="60%" stop-color="#ffffff" stop-opacity="0.07"/>
    <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="nb_dot1" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#ffcc00"/>
    <stop offset="100%" stop-color="#ff8800"/>
  </radialGradient>
  <radialGradient id="nb_dot2" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#aaffcc"/>
    <stop offset="100%" stop-color="#00cc66"/>
  </radialGradient>
  <filter id="nb_blur1"><feGaussianBlur stdDeviation="55"/></filter>
</defs>
<rect width="512" height="512" fill="#000820"/>
<ellipse cx="220" cy="210" rx="200" ry="180" fill="url(#nb_glow1)" filter="url(#nb_blur1)"/>
<ellipse cx="340" cy="320" rx="160" ry="140" fill="url(#nb_glow2)" filter="url(#nb_blur1)"/>
<circle cx="60" cy="50" r="1.5" fill="#ffffff" fill-opacity="0.6"/>
<circle cx="130" cy="30" r="1" fill="#ffffff" fill-opacity="0.5"/>
<circle cx="200" cy="60" r="1.5" fill="#ffffff" fill-opacity="0.4"/>
<circle cx="350" cy="40" r="1" fill="#ffffff" fill-opacity="0.6"/>
<circle cx="420" cy="70" r="2" fill="#ffffff" fill-opacity="0.5"/>
<circle cx="470" cy="30" r="1" fill="#ffffff" fill-opacity="0.4"/>
<circle cx="480" cy="100" r="1.5" fill="#ffffff" fill-opacity="0.5"/>
<circle cx="40" cy="150" r="1" fill="#ffffff" fill-opacity="0.4"/>
<circle cx="80" cy="420" r="1.5" fill="#ffffff" fill-opacity="0.3"/>
<circle cx="450" cy="450" r="1" fill="#ffffff" fill-opacity="0.4"/>
<circle cx="490" cy="390" r="1.5" fill="#ffffff" fill-opacity="0.5"/>
<circle cx="256" cy="248" r="188" fill="url(#nb_ballGrad)"/>
<circle cx="256" cy="248" r="188" fill="url(#nb_glassShine)"/>
<circle cx="256" cy="248" r="188" fill="none" stroke="#ffffff" stroke-width="1.5" stroke-opacity="0.35"/>
<circle cx="256" cy="248" r="176" fill="none" stroke="#ffffff" stroke-width="0.7" stroke-opacity="0.15"/>
<path d="M 112 160 Q 200 110 316 138" fill="none" stroke="#ffffff" stroke-width="2.8" stroke-opacity="0.45" stroke-linecap="round"/>
<polygon points="256,116 372,168 256,220 140,168" fill="none" stroke="#ffffff" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"/>
<path d="M 178,180 L 178,252 Q 178,276 256,288 Q 334,276 334,252 L 334,180" fill="none" stroke="#ffffff" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"/>
<line x1="178" y1="180" x2="178" y2="256" stroke="#ffffff" stroke-width="7" stroke-linecap="round"/>
<circle cx="178" cy="263" r="13" fill="none" stroke="#ffffff" stroke-width="7"/>
<line x1="172" y1="276" x2="162" y2="308" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
<line x1="178" y1="276" x2="178" y2="310" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
<line x1="184" y1="276" x2="194" y2="308" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
<rect x="210" y="300" width="92" height="68" rx="10" fill="none" stroke="#ffffff" stroke-width="5" stroke-opacity="0.75"/>
<rect x="220" y="312" width="14" height="14" rx="3" fill="#ffffff" fill-opacity="0.22" stroke="#ffffff" stroke-width="2.5"/>
<polyline points="222,319 226,323 232,314" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="240" y="315" width="54" height="6" rx="3" fill="#ffffff" fill-opacity="0.55"/>
<rect x="220" y="332" width="14" height="14" rx="3" fill="#ffffff" fill-opacity="0.22" stroke="#ffffff" stroke-width="2.5"/>
<polyline points="222,339 226,343 232,334" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="240" y="335" width="42" height="6" rx="3" fill="#ffffff" fill-opacity="0.55"/>
<rect x="220" y="352" width="14" height="14" rx="3" fill="#ffffff" fill-opacity="0.22" stroke="#ffffff" stroke-width="2.5"/>
<rect x="240" y="355" width="50" height="6" rx="3" fill="#ffffff" fill-opacity="0.30"/>
<text x="256" y="410" text-anchor="middle" font-family="Arial, sans-serif" font-size="30" font-weight="800" letter-spacing="5" fill="#ffffff" fill-opacity="0.93">AMALIYOT</text>
<circle cx="412" cy="128" r="26" fill="url(#nb_dot1)"/>
<circle cx="402" cy="118" r="10" fill="#ffffff" fill-opacity="0.28"/>
<circle cx="422" cy="370" r="16" fill="url(#nb_dot2)"/>
<circle cx="418" cy="366" r="5.5" fill="#ffffff" fill-opacity="0.22"/>
<circle cx="100" cy="378" r="28" fill="url(#nb_dot1)" fill-opacity="0.8"/>
<circle cx="92" cy="370" r="10" fill="#ffffff" fill-opacity="0.2"/>
<circle cx="96" cy="128" r="10" fill="url(#nb_dot2)" fill-opacity="0.75"/>
<circle cx="430" cy="240" r="6" fill="#60aaff" fill-opacity="0.7"/>
<circle cx="86" cy="270" r="5" fill="#0088ff" fill-opacity="0.6"/>
<circle cx="370" cy="430" r="8" fill="#60aaff" fill-opacity="0.5"/>
</svg>
''';

const String _svgBluePurple = '''
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
<defs>
  <radialGradient id="bp_glow1" cx="45%" cy="40%" r="65%">
    <stop offset="0%" stop-color="#a0c4ff" stop-opacity="0.85"/>
    <stop offset="100%" stop-color="#8800cc" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="bp_glow2" cx="70%" cy="65%" r="50%">
    <stop offset="0%" stop-color="#8800cc" stop-opacity="0.6"/>
    <stop offset="100%" stop-color="#8800cc" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="bp_ballGrad" cx="42%" cy="36%" r="68%">
    <stop offset="0%" stop-color="#a0c4ff"/>
    <stop offset="45%" stop-color="#4060ff"/>
    <stop offset="100%" stop-color="#8800cc"/>
  </radialGradient>
  <radialGradient id="bp_glassShine" cx="38%" cy="28%" r="55%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.40"/>
    <stop offset="60%" stop-color="#ffffff" stop-opacity="0.08"/>
    <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="bp_dot1" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#ff80cc"/>
    <stop offset="100%" stop-color="#cc0077"/>
  </radialGradient>
  <radialGradient id="bp_dot2" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#aaff44"/>
    <stop offset="100%" stop-color="#44aa00"/>
  </radialGradient>
  <filter id="bp_blur1"><feGaussianBlur stdDeviation="55"/></filter>
  <filter id="bp_blur2"><feGaussianBlur stdDeviation="30"/></filter>
</defs>
<rect width="512" height="512" fill="#0a0520"/>
<ellipse cx="220" cy="210" rx="200" ry="180" fill="url(#bp_glow1)" filter="url(#bp_blur1)"/>
<ellipse cx="340" cy="320" rx="160" ry="140" fill="url(#bp_glow2)" filter="url(#bp_blur1)"/>
<circle cx="256" cy="248" r="188" fill="url(#bp_ballGrad)"/>
<circle cx="256" cy="248" r="188" fill="url(#bp_glassShine)"/>
<circle cx="256" cy="248" r="188" fill="none" stroke="#ffffff" stroke-width="1.5" stroke-opacity="0.35"/>
<circle cx="256" cy="248" r="176" fill="none" stroke="#ffffff" stroke-width="0.7" stroke-opacity="0.15"/>
<path d="M 112 160 Q 200 110 316 138" fill="none" stroke="#ffffff" stroke-width="2.8" stroke-opacity="0.45" stroke-linecap="round"/>
<polygon points="256,116 372,168 256,220 140,168" fill="none" stroke="#ffffff" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"/>
<path d="M 178,180 L 178,252 Q 178,276 256,288 Q 334,276 334,252 L 334,180" fill="none" stroke="#ffffff" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"/>
<line x1="178" y1="180" x2="178" y2="256" stroke="#ffffff" stroke-width="7" stroke-linecap="round"/>
<circle cx="178" cy="263" r="13" fill="none" stroke="#ffffff" stroke-width="7"/>
<line x1="172" y1="276" x2="162" y2="308" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
<line x1="178" y1="276" x2="178" y2="310" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
<line x1="184" y1="276" x2="194" y2="308" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
<rect x="210" y="300" width="92" height="68" rx="10" fill="none" stroke="#ffffff" stroke-width="5" stroke-opacity="0.75"/>
<rect x="220" y="312" width="14" height="14" rx="3" fill="#ffffff" fill-opacity="0.22" stroke="#ffffff" stroke-width="2.5"/>
<polyline points="222,319 226,323 232,314" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="240" y="315" width="54" height="6" rx="3" fill="#ffffff" fill-opacity="0.55"/>
<rect x="220" y="332" width="14" height="14" rx="3" fill="#ffffff" fill-opacity="0.22" stroke="#ffffff" stroke-width="2.5"/>
<polyline points="222,339 226,343 232,334" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="240" y="335" width="42" height="6" rx="3" fill="#ffffff" fill-opacity="0.55"/>
<rect x="220" y="352" width="14" height="14" rx="3" fill="#ffffff" fill-opacity="0.22" stroke="#ffffff" stroke-width="2.5"/>
<rect x="240" y="355" width="50" height="6" rx="3" fill="#ffffff" fill-opacity="0.30"/>
<text x="256" y="410" text-anchor="middle" font-family="Arial, sans-serif" font-size="30" font-weight="800" letter-spacing="5" fill="#ffffff" fill-opacity="0.93">AMALIYOT</text>
<circle cx="412" cy="128" r="26" fill="url(#bp_dot1)"/>
<circle cx="402" cy="118" r="10" fill="#ffffff" fill-opacity="0.28"/>
<circle cx="422" cy="370" r="16" fill="url(#bp_dot2)"/>
<circle cx="418" cy="366" r="5.5" fill="#ffffff" fill-opacity="0.22"/>
<circle cx="100" cy="378" r="28" fill="url(#bp_dot1)" fill-opacity="0.8"/>
<circle cx="92" cy="370" r="10" fill="#ffffff" fill-opacity="0.2"/>
<circle cx="96" cy="128" r="10" fill="url(#bp_dot2)" fill-opacity="0.75"/>
<circle cx="430" cy="240" r="6" fill="#a0c4ff" fill-opacity="0.7"/>
<circle cx="86" cy="270" r="5" fill="#cc88ff" fill-opacity="0.6"/>
<circle cx="370" cy="430" r="8" fill="#ff80cc" fill-opacity="0.5"/>
</svg>
''';

// ─── Round ikonkalar SVG ───────────────────────────────────────────

const String _svgTunKokiRound = '''
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
<defs>
  <clipPath id="tk_circ"><circle cx="256" cy="256" r="256"/></clipPath>
  <radialGradient id="tk_bgMain" cx="38%" cy="32%" r="75%">
    <stop offset="0%" stop-color="#1a5fcc"/>
    <stop offset="45%" stop-color="#0a2f88"/>
    <stop offset="100%" stop-color="#030e2a"/>
  </radialGradient>
  <radialGradient id="tk_glowTop" cx="35%" cy="28%" r="55%">
    <stop offset="0%" stop-color="#4488ff" stop-opacity="0.55"/>
    <stop offset="100%" stop-color="#4488ff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="tk_glowBottom" cx="75%" cy="70%" r="45%">
    <stop offset="0%" stop-color="#003399" stop-opacity="0.6"/>
    <stop offset="100%" stop-color="#003399" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="tk_dot1" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#ffcc00"/>
    <stop offset="100%" stop-color="#ff8800"/>
  </radialGradient>
  <radialGradient id="tk_dot2" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#aaffcc"/>
    <stop offset="100%" stop-color="#00cc66"/>
  </radialGradient>
  <filter id="tk_blur1"><feGaussianBlur stdDeviation="40"/></filter>
  <filter id="tk_blur2"><feGaussianBlur stdDeviation="18"/></filter>
</defs>
<g clip-path="url(#tk_circ)">
  <rect width="512" height="512" fill="url(#tk_bgMain)"/>
  <ellipse cx="180" cy="160" rx="200" ry="180" fill="url(#tk_glowTop)" filter="url(#tk_blur1)"/>
  <ellipse cx="360" cy="340" rx="160" ry="140" fill="url(#tk_glowBottom)" filter="url(#tk_blur1)"/>
  <circle cx="60" cy="55" r="1.5" fill="#ffffff" fill-opacity="0.5"/>
  <circle cx="140" cy="30" r="1" fill="#ffffff" fill-opacity="0.4"/>
  <circle cx="210" cy="65" r="1.5" fill="#ffffff" fill-opacity="0.35"/>
  <circle cx="360" cy="42" r="1" fill="#ffffff" fill-opacity="0.5"/>
  <circle cx="430" cy="75" r="2" fill="#ffffff" fill-opacity="0.4"/>
  <circle cx="475" cy="32" r="1" fill="#ffffff" fill-opacity="0.35"/>
  <circle cx="485" cy="105" r="1.5" fill="#ffffff" fill-opacity="0.4"/>
  <circle cx="42" cy="155" r="1" fill="#ffffff" fill-opacity="0.35"/>
  <circle cx="82" cy="425" r="1.5" fill="#ffffff" fill-opacity="0.25"/>
  <circle cx="455" cy="455" r="1" fill="#ffffff" fill-opacity="0.35"/>
  <circle cx="492" cy="395" r="1.5" fill="#ffffff" fill-opacity="0.4"/>
  <polygon points="256,104 384,162 256,220 128,162" fill="none" stroke="#ffffff" stroke-width="10" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 166,174 L 166,254 Q 166,282 256,296 Q 346,282 346,254 L 346,174" fill="none" stroke="#ffffff" stroke-width="10" stroke-linejoin="round" stroke-linecap="round"/>
  <line x1="166" y1="174" x2="166" y2="258" stroke="#ffffff" stroke-width="8" stroke-linecap="round"/>
  <circle cx="166" cy="266" r="14" fill="none" stroke="#ffffff" stroke-width="8"/>
  <line x1="160" y1="280" x2="149" y2="314" stroke="#ffffff" stroke-width="5.5" stroke-linecap="round"/>
  <line x1="166" y1="280" x2="166" y2="316" stroke="#ffffff" stroke-width="5.5" stroke-linecap="round"/>
  <line x1="172" y1="280" x2="183" y2="314" stroke="#ffffff" stroke-width="5.5" stroke-linecap="round"/>
  <rect x="206" y="308" width="100" height="72" rx="11" fill="none" stroke="#ffffff" stroke-width="5.5" stroke-opacity="0.78"/>
  <rect x="216" y="320" width="15" height="15" rx="3.5" fill="#ffffff" fill-opacity="0.2" stroke="#ffffff" stroke-width="2.5"/>
  <polyline points="218,327 222,332 230,321" fill="none" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="237" y="323" width="58" height="7" rx="3.5" fill="#ffffff" fill-opacity="0.55"/>
  <rect x="216" y="341" width="15" height="15" rx="3.5" fill="#ffffff" fill-opacity="0.2" stroke="#ffffff" stroke-width="2.5"/>
  <polyline points="218,348 222,353 230,342" fill="none" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="237" y="344" width="46" height="7" rx="3.5" fill="#ffffff" fill-opacity="0.55"/>
  <rect x="216" y="362" width="15" height="15" rx="3.5" fill="#ffffff" fill-opacity="0.2" stroke="#ffffff" stroke-width="2.5"/>
  <rect x="237" y="365" width="54" height="7" rx="3.5" fill="#ffffff" fill-opacity="0.28"/>
  <text x="256" y="424" text-anchor="middle" font-family="Arial, sans-serif" font-size="32" font-weight="800" letter-spacing="5" fill="#ffffff" fill-opacity="0.92">AMALIYOT</text>
  <circle cx="418" cy="122" r="28" fill="url(#tk_dot1)"/>
  <circle cx="408" cy="112" r="11" fill="#ffffff" fill-opacity="0.28"/>
  <circle cx="426" cy="374" r="17" fill="url(#tk_dot2)"/>
  <circle cx="422" cy="370" r="6" fill="#ffffff" fill-opacity="0.22"/>
  <circle cx="96" cy="382" r="30" fill="url(#tk_dot1)" fill-opacity="0.8"/>
  <circle cx="88" cy="374" r="11" fill="#ffffff" fill-opacity="0.2"/>
  <circle cx="94" cy="126" r="11" fill="url(#tk_dot2)" fill-opacity="0.75"/>
  <circle cx="434" cy="244" r="6.5" fill="#6699ff" fill-opacity="0.7"/>
  <circle cx="82" cy="274" r="5.5" fill="#4477ff" fill-opacity="0.6"/>
  <circle cx="374" cy="434" r="8.5" fill="#60aaff" fill-opacity="0.5"/>
  <circle cx="256" cy="256" r="254" fill="none" stroke="#4488ff" stroke-width="2" stroke-opacity="0.18"/>
</g>
</svg>
''';

const String _svgKokBinafsha = '''
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
<defs>
  <clipPath id="kb_circ"><circle cx="256" cy="256" r="256"/></clipPath>
  <radialGradient id="kb_bgMain" cx="40%" cy="35%" r="75%">
    <stop offset="0%" stop-color="#7b5ea7"/>
    <stop offset="40%" stop-color="#3a3aaa"/>
    <stop offset="100%" stop-color="#1a1060"/>
  </radialGradient>
  <radialGradient id="kb_glowTop" cx="38%" cy="30%" r="55%">
    <stop offset="0%" stop-color="#aa88ff" stop-opacity="0.6"/>
    <stop offset="100%" stop-color="#aa88ff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="kb_glowRight" cx="80%" cy="55%" r="45%">
    <stop offset="0%" stop-color="#4455ff" stop-opacity="0.5"/>
    <stop offset="100%" stop-color="#4455ff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="kb_dot1" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#ff80cc"/>
    <stop offset="100%" stop-color="#cc0077"/>
  </radialGradient>
  <radialGradient id="kb_dot2" cx="30%" cy="25%" r="70%">
    <stop offset="0%" stop-color="#aaff44"/>
    <stop offset="100%" stop-color="#44aa00"/>
  </radialGradient>
  <filter id="kb_blur1"><feGaussianBlur stdDeviation="40"/></filter>
</defs>
<g clip-path="url(#kb_circ)">
  <rect width="512" height="512" fill="url(#kb_bgMain)"/>
  <ellipse cx="190" cy="170" rx="210" ry="185" fill="url(#kb_glowTop)" filter="url(#kb_blur1)"/>
  <ellipse cx="370" cy="330" rx="170" ry="150" fill="url(#kb_glowRight)" filter="url(#kb_blur1)"/>
  <circle cx="58" cy="52" r="1.5" fill="#ffffff" fill-opacity="0.45"/>
  <circle cx="138" cy="28" r="1" fill="#ffffff" fill-opacity="0.38"/>
  <circle cx="208" cy="63" r="1.5" fill="#ffffff" fill-opacity="0.32"/>
  <circle cx="358" cy="40" r="1" fill="#ffffff" fill-opacity="0.45"/>
  <circle cx="428" cy="73" r="2" fill="#ffffff" fill-opacity="0.38"/>
  <circle cx="473" cy="30" r="1" fill="#ffffff" fill-opacity="0.32"/>
  <circle cx="483" cy="103" r="1.5" fill="#ffffff" fill-opacity="0.38"/>
  <circle cx="40" cy="153" r="1" fill="#ffffff" fill-opacity="0.32"/>
  <circle cx="80" cy="423" r="1.5" fill="#ffffff" fill-opacity="0.22"/>
  <circle cx="453" cy="453" r="1" fill="#ffffff" fill-opacity="0.32"/>
  <polygon points="256,104 384,162 256,220 128,162" fill="none" stroke="#ffffff" stroke-width="10" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 166,174 L 166,254 Q 166,282 256,296 Q 346,282 346,254 L 346,174" fill="none" stroke="#ffffff" stroke-width="10" stroke-linejoin="round" stroke-linecap="round"/>
  <line x1="166" y1="174" x2="166" y2="258" stroke="#ffffff" stroke-width="8" stroke-linecap="round"/>
  <circle cx="166" cy="266" r="14" fill="none" stroke="#ffffff" stroke-width="8"/>
  <line x1="160" y1="280" x2="149" y2="314" stroke="#ffffff" stroke-width="5.5" stroke-linecap="round"/>
  <line x1="166" y1="280" x2="166" y2="316" stroke="#ffffff" stroke-width="5.5" stroke-linecap="round"/>
  <line x1="172" y1="280" x2="183" y2="314" stroke="#ffffff" stroke-width="5.5" stroke-linecap="round"/>
  <rect x="206" y="308" width="100" height="72" rx="11" fill="none" stroke="#ffffff" stroke-width="5.5" stroke-opacity="0.78"/>
  <rect x="216" y="320" width="15" height="15" rx="3.5" fill="#ffffff" fill-opacity="0.2" stroke="#ffffff" stroke-width="2.5"/>
  <polyline points="218,327 222,332 230,321" fill="none" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="237" y="323" width="58" height="7" rx="3.5" fill="#ffffff" fill-opacity="0.55"/>
  <rect x="216" y="341" width="15" height="15" rx="3.5" fill="#ffffff" fill-opacity="0.2" stroke="#ffffff" stroke-width="2.5"/>
  <polyline points="218,348 222,353 230,342" fill="none" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="237" y="344" width="46" height="7" rx="3.5" fill="#ffffff" fill-opacity="0.55"/>
  <rect x="216" y="362" width="15" height="15" rx="3.5" fill="#ffffff" fill-opacity="0.2" stroke="#ffffff" stroke-width="2.5"/>
  <rect x="237" y="365" width="54" height="7" rx="3.5" fill="#ffffff" fill-opacity="0.28"/>
  <text x="256" y="424" text-anchor="middle" font-family="Arial, sans-serif" font-size="32" font-weight="800" letter-spacing="5" fill="#ffffff" fill-opacity="0.92">AMALIYOT</text>
  <circle cx="418" cy="122" r="28" fill="url(#kb_dot1)"/>
  <circle cx="408" cy="112" r="11" fill="#ffffff" fill-opacity="0.28"/>
  <circle cx="426" cy="374" r="17" fill="url(#kb_dot2)"/>
  <circle cx="422" cy="370" r="6" fill="#ffffff" fill-opacity="0.22"/>
  <circle cx="96" cy="382" r="30" fill="url(#kb_dot1)" fill-opacity="0.8"/>
  <circle cx="88" cy="374" r="11" fill="#ffffff" fill-opacity="0.2"/>
  <circle cx="94" cy="126" r="11" fill="url(#kb_dot2)" fill-opacity="0.75"/>
  <circle cx="434" cy="244" r="6.5" fill="#cc99ff" fill-opacity="0.7"/>
  <circle cx="82" cy="274" r="5.5" fill="#aa66ff" fill-opacity="0.6"/>
  <circle cx="374" cy="434" r="8.5" fill="#ff80cc" fill-opacity="0.5"/>
  <circle cx="256" cy="256" r="254" fill="none" stroke="#aa88ff" stroke-width="2" stroke-opacity="0.18"/>
</g>
</svg>
''';

// ─────────────────────────────────────────────
// Ikonka modeli
// ─────────────────────────────────────────────
class _IconOption {
  final String label;
  final String svgData;
  const _IconOption({required this.label, required this.svgData});
}

// ─────────────────────────────────────────────
// AppearanceScreen
// ─────────────────────────────────────────────
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  String _theme = 'light';
  int _selectedIcon = 0;

  static const List<_IconOption> _icons = [
    _IconOption(label: 'Tun Ko\'k',       svgData: _svgNightBlue),
    _IconOption(label: 'Ko\'k-Binafsha',  svgData: _svgBluePurple),
    _IconOption(label: 'Tun Ko\'k (Yum)', svgData: _svgTunKokiRound),
    _IconOption(label: 'Ko\'k-Binafsha (Yum)', svgData: _svgKokBinafsha),
  ];

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadIcon();
  }

  Future<void> _loadTheme() async {
    final t = await ThemeService.getTheme();
    if (!mounted) return;
    setState(() => _theme = t);
  }

  Future<void> _loadIcon() async {
    final i = await IconService.getIcon();
    if (!mounted) return;
    setState(() => _selectedIcon = i);
  }

  Future<void> _changeTheme(String value) async {
    await ThemeService.saveTheme(value);
    setState(() => _theme = value);
    MyApp.of(context)?.changeTheme(value);
  }

  Future<void> _changeIcon(int index) async {
    try {
      await IconService.changeIcon(index);
      setState(() => _selectedIcon = index);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_icons[index].label} ikonkasi tanlandi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ikonkani o'zgartirib bo'lmadi"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomAppBar(title: "Ko'rinish"),

          // ── TEMA bo'limi ───────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Tema',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          RadioListTile(
            value: 'light',
            groupValue: _theme,
            title: const Text("Yorug' (Light)"),
            onChanged: (v) => _changeTheme(v!),
          ),
          RadioListTile(
            value: 'dark',
            groupValue: _theme,
            title: const Text("Qorong'i (Dark)"),
            onChanged: (v) => _changeTheme(v!),
          ),
          RadioListTile(
            value: 'system',
            groupValue: _theme,
            title: const Text("Tizim bilan bir xil"),
            onChanged: (v) => _changeTheme(v!),
          ),

          const Divider(),

          // ── IKONKA bo'limi ─────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Ilova Ikonkasi ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_icons.length, (i) {
                final isSelected = _selectedIcon == i;
                return GestureDetector(
                  onTap: () => _changeIcon(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tanlangan bo'lsa ko'k border
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                              : null,
                        ),
                        child: ClipOval(
                          child: SvgPicture.string(
                            _icons[i].svgData,
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _icons[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.blue : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.check_circle,
                            color: Colors.blue, size: 16),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}