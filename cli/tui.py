"""Curses terminal UI for rNitro CLI (btop-style)."""

from __future__ import annotations

import curses
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from monitor import MetricsEngine, Snapshot

VERSION = "v0.2-cli"


def _fmt_uptime(seconds: float) -> str:
    s = int(seconds)
    d, s = divmod(s, 86400)
    h, s = divmod(s, 3600)
    m, s = divmod(s, 60)
    if d:
        return f"{d}d {h:02d}:{m:02d}:{s:02d}"
    return f"{h:02d}:{m:02d}:{s:02d}"


def _bar(pct: float, width: int) -> str:
    pct = max(0.0, min(100.0, pct))
    filled = int(round(width * pct / 100.0))
    return "█" * filled + "░" * (width - filled)


def _sparkline(values: list[float], width: int) -> str:
    if not values:
        return " " * width
    chunk = max(1, len(values) // width)
    chars = "▁▂▃▄▅▆▇█"
    out = []
    for i in range(width):
        chunk_vals = values[i * chunk : (i + 1) * chunk]
        if not chunk_vals:
            out.append(" ")
            continue
        v = sum(chunk_vals) / len(chunk_vals)
        idx = min(len(chars) - 1, int(v / 100.0 * (len(chars) - 1)))
        out.append(chars[idx])
    return "".join(out)


def _color_for_pct(stdscr: curses.window, pct: float, pair_ok: int, pair_warn: int, pair_bad: int) -> int:
    if pct >= 85:
        return pair_bad
    if pct >= 60:
        return pair_warn
    return pair_ok


def _safe_addstr(win: curses.window, y: int, x: int, text: str, attr: int = 0) -> None:
    if y < 0 or x < 0:
        return
    try:
        max_y, max_x = win.getmaxyx()
    except curses.error:
        return
    if y >= max_y or x >= max_x:
        return
    width = max_x - x - 1
    if width <= 0:
        return
    try:
        win.addstr(y, x, text[:width], attr)
    except curses.error:
        pass


def _draw_box(win: curses.window, y: int, x: int, h: int, w: int, title: str) -> None:
    if h < 2 or w < 2:
        return
    top = "┌" + "─" * (w - 2) + "┐"
    mid = "│" + " " * (w - 2) + "│"
    bot = "└" + "─" * (w - 2) + "┘"
    _safe_addstr(win, y, x, top)
    for row in range(1, h - 1):
        _safe_addstr(win, y + row, x, mid)
    _safe_addstr(win, y + h - 1, x, bot)
    label = f" {title} "
    if len(label) < w - 2:
        _safe_addstr(win, y, x + 2, label[: w - 4], curses.A_BOLD)


def _render(stdscr: curses.window, snap: Snapshot, pairs: dict[str, int]) -> None:
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    footer_y = h - 2 if h > 1 else 0
    if h < 12 or w < 60:
        _safe_addstr(stdscr, 0, 0, "Terminal too small — need at least 60×12")
        stdscr.refresh()
        return

    header = f" rNitro TUI {VERSION}  │  {snap.hostname}  │  up {_fmt_uptime(snap.uptime_s)}  │  load {snap.load[0]:.2f} {snap.load[1]:.2f} {snap.load[2]:.2f}"
    _safe_addstr(stdscr, 0, 0, header, curses.A_BOLD)

    col_w = (w - 4) // 3
    top_y = 2
    box_h = 7

    # CPU
    _draw_box(stdscr, top_y, 1, box_h, col_w, "CPU")
    cpu_attr = _color_for_pct(stdscr, snap.cpu_percent, pairs["ok"], pairs["warn"], pairs["bad"])
    bar_w = max(8, col_w - 6)
    _safe_addstr(stdscr, top_y + 1, 3, f"{snap.cpu_percent:5.1f}%  {snap.core_count} cores", cpu_attr)
    _safe_addstr(stdscr, top_y + 2, 3, _bar(snap.cpu_percent, bar_w), cpu_attr)
    _safe_addstr(stdscr, top_y + 3, 3, snap.cpu_name or "CPU")
    _safe_addstr(stdscr, top_y + 4, 3, _sparkline(snap.cpu_history, bar_w), pairs["accent"])

    # Memory
    mx = 1 + col_w + 1
    _draw_box(stdscr, top_y, mx, box_h, col_w, "Memory")
    mem_attr = _color_for_pct(stdscr, snap.mem_percent, pairs["ok"], pairs["warn"], pairs["bad"])
    _safe_addstr(stdscr, top_y + 1, mx + 2, f"{snap.mem_percent:5.1f}%", mem_attr)
    _safe_addstr(stdscr, top_y + 2, mx + 2, f"{snap.mem_used_gb:.1f} / {snap.mem_total_gb:.1f} GB")
    _safe_addstr(stdscr, top_y + 3, mx + 2, f"Swap/wired ~{snap.swap_gb:.1f} GB")
    _safe_addstr(stdscr, top_y + 4, mx + 2, _sparkline(snap.mem_history, bar_w), pairs["accent"])

    # Disk + Network
    dx = mx + col_w + 1
    _draw_box(stdscr, top_y, dx, box_h, w - dx - 1, "Disk / Net")
    d_attr = _color_for_pct(stdscr, snap.disk_percent, pairs["ok"], pairs["warn"], pairs["bad"])
    _safe_addstr(stdscr, top_y + 1, dx + 2, f"Disk {snap.disk_percent:.0f}%  {snap.disk_used_gb:.0f}/{snap.disk_total_gb:.0f} GB", d_attr)
    _safe_addstr(stdscr, top_y + 2, dx + 2, f"R {snap.disk_read_mbps:.1f}  W {snap.disk_write_mbps:.1f} MB/s")
    net_line = f"{snap.net_iface or '—'}  ↓{snap.net_down_mbps:.1f} ↑{snap.net_up_mbps:.1f} MB/s"
    _safe_addstr(stdscr, top_y + 3, dx + 2, net_line)
    if snap.net_ip:
        _safe_addstr(stdscr, top_y + 4, dx + 2, snap.net_ip)
    if snap.battery_pct is not None:
        bat = f"Battery {snap.battery_pct}% {snap.battery_status}"
        _safe_addstr(stdscr, top_y + 5, dx + 2, bat, pairs["accent"])

    proc_y = top_y + box_h + 1
    proc_h = max(4, (footer_y - proc_y - 1) // 2)
    proc_w = w - 2

    _draw_box(stdscr, proc_y, 1, proc_h, proc_w, "Top CPU")
    _safe_addstr(stdscr, proc_y + 1, 3, f"{'PROCESS':<20} {'PID':>7} {'CPU%':>7} {'MEM':>9}", curses.A_UNDERLINE)
    row = proc_y + 2
    for p in snap.top_cpu:
        if row >= proc_y + proc_h - 1:
            break
        name = (p.name or "?")[:20]
        line = f"{name:<20} {p.pid:>7} {p.cpu:>6.1f}% {p.mem_mb:>7.0f}M"
        attr = pairs["bad"] if p.cpu >= 50 else 0
        _safe_addstr(stdscr, row, 3, line, attr)
        row += 1

    mem_y = proc_y + proc_h
    mem_h = max(4, footer_y - mem_y)
    _draw_box(stdscr, mem_y, 1, mem_h, proc_w, "Top Memory")
    _safe_addstr(stdscr, mem_y + 1, 3, f"{'PROCESS':<20} {'PID':>7} {'CPU%':>7} {'MEM':>9}", curses.A_UNDERLINE)
    row = mem_y + 2
    for p in snap.top_mem:
        if row >= mem_y + mem_h - 1:
            break
        name = (p.name or "?")[:20]
        line = f"{name:<20} {p.pid:>7} {p.cpu:>6.1f}% {p.mem_mb:>7.0f}M"
        _safe_addstr(stdscr, row, 3, line)
        row += 1

    footer = " q quit │ r refresh │ ? help │ psutil: pip3 install psutil "
    _safe_addstr(stdscr, footer_y, 0, footer, curses.A_DIM)

    stdscr.refresh()


def run_tui(engine: MetricsEngine) -> int:
    def _main(stdscr: curses.window) -> int:
        curses.curs_set(0)
        stdscr.nodelay(True)
        stdscr.timeout(200)
        if curses.has_colors():
            curses.start_color()
            curses.use_default_colors()
            curses.init_pair(1, curses.COLOR_GREEN, -1)
            curses.init_pair(2, curses.COLOR_YELLOW, -1)
            curses.init_pair(3, curses.COLOR_RED, -1)
            curses.init_pair(4, curses.COLOR_CYAN, -1)
        pairs = {"ok": curses.color_pair(1), "warn": curses.color_pair(2), "bad": curses.color_pair(3), "accent": curses.color_pair(4)}

        engine.start()
        try:
            while True:
                try:
                    ch = stdscr.getch()
                except curses.error:
                    ch = -1
                if ch in (ord("q"), ord("Q"), 27):
                    break
                if ch in (ord("r"), ord("R")):
                    engine.refresh()
                if ch in (ord("?"), ord("h"), ord("H")):
                    pass  # help shown in footer; extend later
                _render(stdscr, engine.snapshot, pairs)
        finally:
            engine.stop()
        return 0

    return curses.wrapper(_main)