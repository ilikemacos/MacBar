from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, Gdk, Gio, GLib, Gtk  # noqa: E402

from . import CURRENT_VERSION
from .advisor import AdvisorThresholds, SystemAdvisor
from .chat import DEFAULT_MODELS, PROVIDER_LABELS, PROVIDERS, ChatMessage, complete_async
from .cleaner import AppCleaner, InstalledApp, fmt_bytes
from .config import load as load_config, save as save_config
from .monitors import SystemMonitor
from .update import check_update
from .weather import WeatherService

DARK_CSS = """
window {
  background-color: #0A0A0F;
}
.navigation-sidebar {
  background-color: #0F0F18;
  border-right: 1px solid #2A2A40;
}
.navigation-sidebar row {
  padding: 10px 14px;
  border-radius: 8px;
  margin: 4px 8px;
}
.navigation-sidebar row:selected {
  background-color: rgba(0, 217, 255, 0.12);
}
.metric-card {
  background-color: #13131E;
  border: 1px solid #2A2A40;
  border-radius: 12px;
  padding: 14px 16px;
}
.metric-title {
  color: #6B6B8A;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
}
.metric-value {
  color: #E8E8F0;
  font-size: 15px;
  font-weight: 600;
}
.metric-sub {
  color: #6B6B8A;
  font-size: 11px;
}
progressbar {
  margin-top: 8px;
}
progressbar trough {
  background: #1A1A28;
  border-radius: 6px;
  min-height: 8px;
}
progressbar progress {
  background: linear-gradient(90deg, #00D9FF, #00FF80);
  border-radius: 6px;
  min-height: 8px;
}
.warn-critical {
  color: #FF4040;
  font-weight: 600;
}
.warn-warn {
  color: #FF8C1A;
  font-weight: 600;
}
.warn-info {
  color: #00D9FF;
}
.chat-bubble-user {
  background: rgba(0, 217, 255, 0.1);
  border: 1px solid rgba(0, 217, 255, 0.25);
  border-radius: 10px;
  padding: 10px 12px;
  margin: 4px 0;
}
.chat-bubble-bot {
  background: #13131E;
  border: 1px solid #2A2A40;
  border-radius: 10px;
  padding: 10px 12px;
  margin: 4px 0;
}
.badge-cyan {
  color: #00D9FF;
  font-weight: 600;
}
"""


def _apply_dark_theme(app: Adw.Application) -> None:
    provider = Gtk.CssProvider()
    provider.load_from_data(DARK_CSS.encode("utf-8"))
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )
    style = Adw.StyleManager.get_default()
    style.set_color_scheme(Adw.ColorScheme.FORCE_DARK)


def _metric_card(title: str, value_label: Gtk.Label, sub_label: Gtk.Label, bar: Gtk.ProgressBar) -> Gtk.Box:
    card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    card.add_css_class("metric-card")
    title_lbl = Gtk.Label(label=title, xalign=0)
    title_lbl.add_css_class("metric-title")
    value_label.add_css_class("metric-value")
    sub_label.add_css_class("metric-sub")
    card.append(title_lbl)
    card.append(value_label)
    card.append(sub_label)
    card.append(bar)
    return card


class RnitroWindow(Adw.ApplicationWindow):
    def __init__(self, app: Adw.Application) -> None:
        super().__init__(application=app, title="rNitro")
        self.set_default_size(960, 680)
        self.cfg = load_config()
        self.monitor = SystemMonitor(poll_interval=float(self.cfg.get("poll_interval", 1.0)))
        self.advisor = SystemAdvisor()
        self.advisor.apply_config(self.cfg)
        self.weather = WeatherService()
        self.cleaner = AppCleaner()
        self._chat_history: list[ChatMessage] = []
        self._selected_app: InstalledApp | None = None
        self._chat_busy = False
        self._build_ui()
        self.monitor.start()
        GLib.timeout_add_seconds(1, self._tick)
        if self.cfg.get("show_weather"):
            self.weather.refresh(True, on_done=lambda: GLib.idle_add(self._update_weather_label))

    def _build_ui(self) -> None:
        toast = Adw.ToastOverlay()
        self.toast_overlay = toast
        root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        toast.set_child(root)
        self.set_content(toast)

        sidebar = Gtk.ListBox()
        sidebar.set_size_request(156, -1)
        sidebar.add_css_class("navigation-sidebar")
        self._tab_rows: list[Gtk.ListBoxRow] = []
        for label in ("Monitor", "Advisor", "Chat", "Cleaner"):
            row = Gtk.ListBoxRow()
            lbl = Gtk.Label(label=label, xalign=0)
            lbl.add_css_class("badge-cyan")
            row.set_child(lbl)
            sidebar.append(row)
            self._tab_rows.append(row)
        sidebar.connect("row-selected", self._on_tab)
        root.append(sidebar)

        self.stack = Gtk.Stack()
        self.stack.set_hexpand(True)
        self.stack.add_named(self._monitor_page(), "monitor")
        self.stack.add_named(self._advisor_page(), "advisor")
        self.stack.add_named(self._chat_page(), "chat")
        self.stack.add_named(self._cleaner_page(), "cleaner")
        self.stack.set_visible_child_name("monitor")
        root.append(self.stack)

        header = Adw.HeaderBar()
        title = Gtk.Label(label=f"rNitro {CURRENT_VERSION}")
        title.add_css_class("badge-cyan")
        header.set_title_widget(title)
        settings_btn = Gtk.Button(icon_name="emblem-system-symbolic")
        settings_btn.set_tooltip_text("Settings")
        settings_btn.connect("clicked", self._open_settings)
        header.pack_end(settings_btn)
        self.set_titlebar(header)
        sidebar.select_row(self._tab_rows[0])

    def _on_tab(self, _box: Gtk.ListBox, row: Gtk.ListBoxRow | None) -> None:
        if not row:
            return
        idx = self._tab_rows.index(row)
        names = ["monitor", "advisor", "chat", "cleaner"]
        self.stack.set_visible_child_name(names[idx])

    def _monitor_page(self) -> Gtk.Widget:
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)
        box.set_margin_start(20)
        box.set_margin_end(20)

        self.lbl_battery = Gtk.Label(label="…", xalign=0)
        self.lbl_battery.add_css_class("metric-value")
        bat_sub = Gtk.Label(label="Power", xalign=0)
        bat_sub.add_css_class("metric-sub")
        bat_bar = Gtk.ProgressBar()
        self.bat_bar = bat_bar
        bat_card = _metric_card("BATTERY & POWER", self.lbl_battery, bat_sub, bat_bar)
        box.append(bat_card)

        self.lbl_cpu_val = Gtk.Label(label="…", xalign=0)
        self.lbl_cpu_sub = Gtk.Label(label="…", xalign=0)
        self.cpu_bar = Gtk.ProgressBar()
        box.append(_metric_card("CPU", self.lbl_cpu_val, self.lbl_cpu_sub, self.cpu_bar))

        self.lbl_mem_val = Gtk.Label(label="…", xalign=0)
        self.lbl_mem_sub = Gtk.Label(label="…", xalign=0)
        self.mem_bar = Gtk.ProgressBar()
        box.append(_metric_card("MEMORY", self.lbl_mem_val, self.lbl_mem_sub, self.mem_bar))

        self.lbl_disk_val = Gtk.Label(label="…", xalign=0)
        self.lbl_disk_sub = Gtk.Label(label="…", xalign=0)
        self.disk_bar = Gtk.ProgressBar()
        box.append(_metric_card("DISK", self.lbl_disk_val, self.lbl_disk_sub, self.disk_bar))

        self.lbl_net_val = Gtk.Label(label="…", xalign=0)
        self.lbl_net_sub = Gtk.Label(label="…", xalign=0)
        self.net_bar = Gtk.ProgressBar()
        self.net_card = _metric_card("NETWORK", self.lbl_net_val, self.lbl_net_sub, self.net_bar)
        box.append(self.net_card)

        self.lbl_gpu_val = Gtk.Label(label="…", xalign=0)
        self.lbl_gpu_sub = Gtk.Label(label="…", xalign=0)
        self.gpu_bar = Gtk.ProgressBar()
        box.append(_metric_card("GPU", self.lbl_gpu_val, self.lbl_gpu_sub, self.gpu_bar))

        self.lbl_sensors = Gtk.Label(label="Sensors: …", xalign=0, wrap=True)
        self.lbl_sensors.add_css_class("metric-sub")
        sens_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        sens_card.add_css_class("metric-card")
        sens_title = Gtk.Label(label="SENSORS", xalign=0)
        sens_title.add_css_class("metric-title")
        sens_card.append(sens_title)
        sens_card.append(self.lbl_sensors)
        box.append(sens_card)

        self.lbl_weather = Gtk.Label(label="", xalign=0)
        self.lbl_weather.add_css_class("metric-sub")
        box.append(self.lbl_weather)

        scroll.set_child(box)
        return scroll

    def _advisor_page(self) -> Gtk.Widget:
        scroll = Gtk.ScrolledWindow()
        self.advisor_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.advisor_box.set_margin_top(16)
        self.advisor_box.set_margin_start(20)
        self.advisor_box.set_margin_end(20)
        self.advisor_box.set_margin_bottom(16)
        placeholder = Gtk.Label(label="Analyzing system metrics…", xalign=0)
        placeholder.add_css_class("metric-sub")
        self.advisor_box.append(placeholder)
        scroll.set_child(self.advisor_box)
        return scroll

    def _chat_page(self) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(14)
        box.set_margin_start(16)
        box.set_margin_end(16)
        box.set_margin_bottom(14)

        row = Gtk.Box(spacing=8)
        self.provider_combo = Gtk.DropDown.new_from_strings(
            [PROVIDER_LABELS.get(p, p) for p in PROVIDERS]
        )
        try:
            idx = PROVIDERS.index(self.cfg.get("chat_provider", "openrouter"))
        except ValueError:
            idx = 0
        self.provider_combo.set_selected(idx)
        row.append(Gtk.Label(label="Provider", xalign=0))
        row.append(self.provider_combo)
        box.append(row)

        self.chat_scroll = Gtk.ScrolledWindow()
        self.chat_scroll.set_vexpand(True)
        self.chat_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.chat_box.set_margin_top(8)
        self.chat_box.set_margin_bottom(8)
        self.chat_scroll.set_child(self.chat_box)
        box.append(self.chat_scroll)

        entry_row = Gtk.Box(spacing=8)
        self.chat_entry = Gtk.Entry()
        self.chat_entry.set_placeholder_text("Ask rNitro about your system…")
        self.chat_entry.set_hexpand(True)
        self.chat_entry.connect("activate", lambda *_: self._send_chat())
        self.send_btn = Gtk.Button(label="Send")
        self.send_btn.add_css_class("suggested-action")
        self.send_btn.connect("clicked", lambda *_: self._send_chat())
        entry_row.append(self.chat_entry)
        entry_row.append(self.send_btn)
        box.append(entry_row)
        return box

    def _cleaner_page(self) -> Gtk.Widget:
        paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL, wide_handle=True)
        paned.set_margin_top(12)
        paned.set_margin_start(12)
        paned.set_margin_end(12)
        paned.set_margin_bottom(12)

        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        top = Gtk.Box(spacing=8)
        rescan = Gtk.Button(label="Rescan apps")
        rescan.connect("clicked", lambda *_: self.cleaner.scan(self._refresh_cleaner_list))
        top.append(rescan)
        self.cleaner_status = Gtk.Label(label="", xalign=0)
        self.cleaner_status.add_css_class("metric-sub")
        top.append(self.cleaner_status)
        left.append(top)

        self.cleaner_list = Gtk.ListBox()
        self.cleaner_list.add_css_class("navigation-sidebar")
        self.cleaner_list.connect("row-selected", self._on_cleaner_select)
        sw_left = Gtk.ScrolledWindow()
        sw_left.set_child(self.cleaner_list)
        sw_left.set_vexpand(True)
        left.append(sw_left)
        paned.set_start_child(left)
        paned.set_resize_start_child(True)
        paned.set_shrink_start_child(False)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.cleaner_detail_title = Gtk.Label(label="Select an app", xalign=0)
        self.cleaner_detail_title.add_css_class("metric-value")
        right.append(self.cleaner_detail_title)
        self.cleaner_detail_body = Gtk.Label(label="", xalign=0, wrap=True)
        self.cleaner_detail_body.add_css_class("metric-sub")
        right.append(self.cleaner_detail_body)
        self.leftover_list = Gtk.ListBox()
        sw_lo = Gtk.ScrolledWindow()
        sw_lo.set_child(self.leftover_list)
        sw_lo.set_vexpand(True)
        right.append(sw_lo)
        self.remove_btn = Gtk.Button(label="Remove selected leftovers")
        self.remove_btn.set_sensitive(False)
        self.remove_btn.connect("clicked", self._remove_leftovers)
        right.append(self.remove_btn)
        paned.set_end_child(right)
        paned.set_resize_end_child(True)

        self.cleaner.scan(self._refresh_cleaner_list)
        return paned

    def _append_chat_bubble(self, who: str, text: str, is_user: bool) -> None:
        frame = Gtk.Frame()
        frame.add_css_class("chat-bubble-user" if is_user else "chat-bubble-bot")
        lbl = Gtk.Label(label=f"{who}: {text}", xalign=0, wrap=True, wrap_mode=Gtk.WrapMode.WORD_CHAR)
        frame.set_child(lbl)
        self.chat_box.append(frame)
        GLib.idle_add(lambda: self.chat_scroll.get_vadjustment().set_value(
            self.chat_scroll.get_vadjustment().get_upper()
        ))

    def _send_chat(self) -> None:
        if self._chat_busy:
            return
        text = self.chat_entry.get_text().strip()
        if not text:
            return
        self.chat_entry.set_text("")
        idx = self.provider_combo.get_selected()
        provider = PROVIDERS[idx] if 0 <= idx < len(PROVIDERS) else "openrouter"
        self.cfg["chat_provider"] = provider
        save_config(self.cfg)
        self._chat_history.append(ChatMessage("user", text))
        self._append_chat_bubble("You", text, True)
        self._chat_busy = True
        self.send_btn.set_sensitive(False)

        def done(reply: str) -> None:
            def ui() -> None:
                self._chat_history.append(ChatMessage("assistant", reply))
                self._append_chat_bubble("rNitro", reply, False)
                self._chat_busy = False
                self.send_btn.set_sensitive(True)
                return False

            GLib.idle_add(ui)

        complete_async(
            provider,
            self.cfg.get("chat_model", "") or DEFAULT_MODELS.get(provider, ""),
            self._chat_history,
            self.cfg,
            on_done=lambda r: GLib.idle_add(lambda: done(r) or False),
        )

    def _refresh_cleaner_list(self) -> None:
        def ui() -> bool:
            while child := self.cleaner_list.get_first_child():
                self.cleaner_list.remove(child)
            for app in self.cleaner.apps:
                row = Gtk.ListBoxRow()
                size = fmt_bytes(app.app_bytes)
                row.set_child(Gtk.Label(label=f"{app.name}\n{size}", xalign=0))
                row.app = app  # type: ignore[attr-defined]
                self.cleaner_list.append(row)
            if self.cleaner.is_scanning:
                self.cleaner_status.set_label("Scanning applications…")
            elif self.cleaner.last_error:
                self.cleaner_status.set_label(f"Error: {self.cleaner.last_error}")
            else:
                self.cleaner_status.set_label(f"{len(self.cleaner.apps)} apps found")
            return False

        GLib.idle_add(ui)

    def _on_cleaner_select(self, _list: Gtk.ListBox, row: Gtk.ListBoxRow | None) -> None:
        if not row:
            return
        app: InstalledApp = row.app  # type: ignore[attr-defined]
        self._selected_app = app
        self.cleaner_detail_title.set_label(app.name)
        self.cleaner_detail_body.set_label(
            f"Exec: {app.exec_path or '—'}\nDesktop: {app.desktop_path}"
        )
        self.remove_btn.set_sensitive(False)
        while child := self.leftover_list.get_first_child():
            self.leftover_list.remove(child)
        if not app.leftovers_loaded:
            loading = Gtk.ListBoxRow()
            loading.set_child(Gtk.Label(label="Scanning leftovers…", xalign=0))
            self.leftover_list.append(loading)
            self.cleaner.load_leftovers(app, self._show_leftovers)
        else:
            self._show_leftovers()

    def _show_leftovers(self) -> None:
        def ui() -> bool:
            while child := self.leftover_list.get_first_child():
                self.leftover_list.remove(child)
            app = self._selected_app
            if not app:
                return False
            if not app.leftovers:
                row = Gtk.ListBoxRow()
                row.set_child(Gtk.Label(label="No leftover folders found.", xalign=0))
                self.leftover_list.append(row)
                return False
            for lo in app.leftovers:
                row = Gtk.ListBoxRow()
                check = Gtk.CheckButton(label=f"{lo.label}: {lo.path} ({fmt_bytes(lo.bytes)})")
                check.path = lo.path  # type: ignore[attr-defined]
                row.set_child(check)
                self.leftover_list.append(row)
            self.remove_btn.set_sensitive(True)
            return False

        GLib.idle_add(ui)

    def _remove_leftovers(self) -> None:
        app = self._selected_app
        if not app:
            return
        paths: list[str] = []
        row = self.leftover_list.get_first_child()
        while row:
            child = row.get_child()
            if isinstance(child, Gtk.CheckButton) and child.get_active():
                paths.append(child.path)  # type: ignore[attr-defined]
            row = row.get_next_sibling()
        if not paths:
            self.toast_overlay.add_toast(Adw.Toast.new("Select leftovers to remove"))
            return
        err = self.cleaner.remove(app, paths)
        if err:
            self.toast_overlay.add_toast(Adw.Toast.new(f"Remove failed: {err}"))
        else:
            self.toast_overlay.add_toast(Adw.Toast.new(f"Removed {len(paths)} item(s)"))
            self._selected_app = None
            self._refresh_cleaner_list()

    def _update_weather_label(self) -> bool:
        if self.weather.is_loading:
            self.lbl_weather.set_label("Weather: loading…")
        elif self.weather.snapshot:
            w = self.weather.snapshot
            hum = f" · {w.humidity}% humidity" if w.humidity is not None else ""
            self.lbl_weather.set_label(f"Weather: {w.temp_c:.0f}°C {w.condition} · {w.city}{hum}")
        elif self.weather.last_error:
            self.lbl_weather.set_label("Weather: unavailable")
        else:
            self.lbl_weather.set_label("")
        return False

    def _refresh_advisor(self, warns: list) -> None:
        while child := self.advisor_box.get_first_child():
            self.advisor_box.remove(child)
        if not warns:
            ok = Gtk.Label(label="All metrics within thresholds.", xalign=0)
            ok.add_css_class("badge-cyan")
            self.advisor_box.append(ok)
            return
        for w in warns:
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            card.add_css_class("metric-card")
            lbl = Gtk.Label(label=f"[{w.level.upper()}] {w.message}", xalign=0, wrap=True)
            if w.level == "critical":
                lbl.add_css_class("warn-critical")
            elif w.level == "warn":
                lbl.add_css_class("warn-warn")
            else:
                lbl.add_css_class("warn-info")
            card.append(lbl)
            self.advisor_box.append(card)

    def _tick(self) -> bool:
        snap = self.monitor.snapshot
        if snap.battery_present:
            self.lbl_battery.set_label(f"{snap.battery_percent}% · {snap.battery_status}")
            self.bat_bar.set_fraction(snap.battery_percent / 100.0)
        else:
            self.lbl_battery.set_label(snap.power_note or "No battery detected")
            self.bat_bar.set_fraction(0.0)

        self.lbl_cpu_val.set_label(f"{snap.cpu_percent:.0f}%")
        self.lbl_cpu_sub.set_label(
            f"{snap.cpu_name[:48]} · {snap.core_count} cores · load {snap.load_avg[0]:.2f}"
        )
        self.cpu_bar.set_fraction(min(1.0, snap.cpu_percent / 100.0))

        self.lbl_mem_val.set_label(f"{snap.mem_percent:.0f}%")
        self.lbl_mem_sub.set_label(f"{snap.mem_used_gb:.1f} / {snap.mem_total_gb:.1f} GB · swap {snap.swap_gb:.1f} GB")
        self.mem_bar.set_fraction(min(1.0, snap.mem_percent / 100.0))

        self.lbl_disk_val.set_label(f"{snap.disk_percent:.0f}%")
        self.lbl_disk_sub.set_label(
            f"{snap.disk_used_gb:.0f} / {snap.disk_total_gb:.0f} GB · R {snap.disk_read_mbps:.1f} W {snap.disk_write_mbps:.1f} MB/s"
        )
        self.disk_bar.set_fraction(min(1.0, snap.disk_percent / 100.0))

        show_net = self.cfg.get("show_network", True)
        self.net_card.set_visible(show_net)
        if show_net:
            self.lbl_net_val.set_label(f"↓ {snap.net_down_mbps:.1f}  ↑ {snap.net_up_mbps:.1f} MB/s")
            self.lbl_net_sub.set_label(f"{snap.net_iface or '—'} · {snap.net_ip or 'no IP'}")
            peak = max(snap.net_down_mbps, snap.net_up_mbps, 1.0)
            self.net_bar.set_fraction(min(1.0, peak / 100.0))

        self.lbl_gpu_val.set_label(f"{snap.gpu_percent:.0f}%")
        self.lbl_gpu_sub.set_label(snap.gpu_name[:60])
        self.gpu_bar.set_fraction(min(1.0, snap.gpu_percent / 100.0))

        if snap.sensors:
            self.lbl_sensors.set_label(", ".join(f"{n} {v}" for n, v in snap.sensors[:8]))
        else:
            self.lbl_sensors.set_label("Install lm-sensors for temperature readings")

        self._update_weather_label()
        warns = self.advisor.evaluate(snap)
        self._refresh_advisor(warns)
        return True

    def _open_settings(self, *_args) -> None:
        dlg = Adw.Window()
        dlg.set_title("rNitro Settings")
        dlg.set_default_size(420, 520)
        dlg.set_transient_for(self)
        dlg.set_modal(True)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        weather_sw = Gtk.Switch(active=self.cfg.get("show_weather", False))
        net_sw = Gtk.Switch(active=self.cfg.get("show_network", True))

        def toggle_weather(sw: Gtk.Switch, *_a) -> None:
            self.cfg["show_weather"] = sw.get_active()
            save_config(self.cfg)
            if sw.get_active():
                self.weather.refresh(True, on_done=lambda: GLib.idle_add(self._update_weather_label))
            else:
                self.weather.snapshot = None
                self._update_weather_label()

        def toggle_net(sw: Gtk.Switch, *_a) -> None:
            self.cfg["show_network"] = sw.get_active()
            save_config(self.cfg)

        weather_sw.connect("notify::active", toggle_weather)
        net_sw.connect("notify::active", toggle_net)

        for label, widget in (
            ("Show weather (IP geolocation)", weather_sw),
            ("Show network stats", net_sw),
        ):
            row = Gtk.Box(spacing=12)
            row.append(Gtk.Label(label=label, xalign=0, hexpand=True))
            row.append(widget)
            box.append(row)

        box.append(Gtk.Separator())
        box.append(Gtk.Label(label="API keys (stored in ~/.config/rnitro/settings.json)", xalign=0))
        key_entries: dict[str, Gtk.Entry] = {}
        keys = self.cfg.setdefault("api_keys", {})
        for provider in PROVIDERS:
            if provider == "ollama":
                continue
            entry = Gtk.Entry()
            entry.set_visibility(False)
            entry.set_text(str(keys.get(provider, "")))
            entry.set_placeholder_text(f"{PROVIDER_LABELS.get(provider, provider)} key")
            key_entries[provider] = entry
            row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            row.append(Gtk.Label(label=PROVIDER_LABELS.get(provider, provider), xalign=0))
            row.append(entry)
            box.append(row)

        model_entry = Gtk.Entry()
        model_entry.set_text(self.cfg.get("chat_model", ""))
        model_entry.set_placeholder_text("Optional custom model override")
        box.append(Gtk.Label(label="Chat model override", xalign=0))
        box.append(model_entry)

        def save_keys(*_a) -> None:
            for provider, entry in key_entries.items():
                keys[provider] = entry.get_text().strip()
            self.cfg["chat_model"] = model_entry.get_text().strip()
            save_config(self.cfg)
            self.toast_overlay.add_toast(Adw.Toast.new("Settings saved"))
            dlg.close()

        save_btn = Gtk.Button(label="Save")
        save_btn.add_css_class("suggested-action")
        save_btn.connect("clicked", save_keys)
        box.append(save_btn)

        scroll = Gtk.ScrolledWindow()
        scroll.set_child(box)
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        dlg.set_content(scroll)
        dlg.present()


class RnitroApp(Adw.Application):
    def __init__(self) -> None:
        super().__init__(application_id="net.getrnitro.linux")
        self._window: RnitroWindow | None = None
        self._indicator = None
        self.connect("activate", self._on_activate)
        self.connect("shutdown", self._on_shutdown)
        self._setup_tray()

    def _setup_tray(self) -> None:
        self._has_tray = False
        try:
            gi.require_version("AyatanaAppIndicator3", "0.1")
            from gi.repository import AyatanaAppIndicator3 as AppIndicator

            self._indicator_cls = AppIndicator
            self._has_tray = True
        except (ImportError, ValueError):
            pass

    def _on_activate(self, app: Adw.Application) -> None:
        if not self._window:
            self._window = RnitroWindow(app)
        self._window.present()
        if self._has_tray and not self._indicator:
            ind = self._indicator_cls.Indicator.new(
                "rnitro",
                "utilities-system-monitor",
                self._indicator_cls.IndicatorCategory.APPLICATION_STATUS,
            )
            ind.set_status(self._indicator_cls.IndicatorStatus.ACTIVE)
            ind.set_title("rNitro")
            menu = Gio.Menu.new()
            menu.append("Open rNitro", "app.activate")
            ind.set_menu(menu)
            self._indicator = ind

    def _on_shutdown(self, *_args) -> None:
        if self._window:
            self._window.monitor.stop()


def run() -> int:
    remote, _meta = check_update()
    app = RnitroApp()
    _apply_dark_theme(app)
    if remote:
        print(f"Update available: {remote} — visit https://getrnitro.netlify.app")
    return app.run(None)