using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Linq;
using System.Management;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

// ── rNitro for Windows ───────────────────────────────────────────────────────
// macOS-style tray popup: full Monitor UI with live system stats.

static class Program {
    [STAThread]
    static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new RNitroContext());
    }
}

static class Theme {
    public static readonly Color BG     = Color.FromArgb(12, 12, 20);
    public static readonly Color Card   = Color.FromArgb(20, 20, 32);
    public static readonly Color Border = Color.FromArgb(40, 40, 60);
    public static readonly Color Green  = Color.FromArgb(26, 230, 120);
    public static readonly Color Cyan   = Color.FromArgb(0, 210, 255);
    public static readonly Color Orange = Color.FromArgb(247, 148, 29);
    public static readonly Color Red    = Color.FromArgb(255, 80, 80);
    public static readonly Color Dim    = Color.FromArgb(120, 120, 150);
    public static readonly Color Text   = Color.White;

    public static Color Usage(float pct) =>
        pct < 50 ? Green : pct < 80 ? Color.FromArgb(255, 200, 50) : Red;

    public static Color Temp(float t) =>
        t < 60 ? Cyan : t < 80 ? Orange : Red;

    public static Font Font(float size, FontStyle style = FontStyle.Regular) =>
        new Font("Segoe UI", size, style);
}

// ── Update check ─────────────────────────────────────────────────────────────
static class UpdateChecker {
    const string CurrentVersion = "v4.2.1-Windows-Final-x86";
    const string VersionUrl     = "https://rnitro.netlify.app/version.json";
    const string DownloadPage   = "https://rnitro.netlify.app";

    static List<int> VersionNumbers(string v) {
        var s = v.Trim();
        if (s.Length > 0 && (s[0] == 'v' || s[0] == 'V')) s = s.Substring(1);
        var nums = new List<int>();
        var cur = "";
        foreach (var ch in s) {
            if (char.IsDigit(ch)) cur += ch;
            else if (cur.Length > 0) { nums.Add(int.Parse(cur)); cur = ""; }
        }
        if (cur.Length > 0) nums.Add(int.Parse(cur));
        return nums;
    }

    static bool IsNewer(string remote, string current) {
        if (remote == current) return false;
        var rn = VersionNumbers(remote);
        var cn = VersionNumbers(current);
        int count = Math.Max(rn.Count, cn.Count);
        for (int i = 0; i < count; i++) {
            int r = i < rn.Count ? rn[i] : 0;
            int c = i < cn.Count ? cn[i] : 0;
            if (r != c) return r > c;
        }
        return string.Compare(remote, current, StringComparison.OrdinalIgnoreCase) > 0;
    }

    public static async Task CheckOnLaunchAsync() {
        try {
            using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(8) };
            http.DefaultRequestHeaders.Add("User-Agent", "rNitro-Windows/" + CurrentVersion);
            var json = await http.GetStringAsync(VersionUrl);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            string latest = root.TryGetProperty("windows", out var win)
                ? win.GetString() ?? ""
                : root.GetProperty("latest").GetString() ?? "";
            if (string.IsNullOrEmpty(latest) || !IsNewer(latest, CurrentVersion)) return;

            MessageBox.Show(
                $"You're running {CurrentVersion}. The latest version is {latest}.\n\nOpening rnitro.netlify.app so you can update.",
                "rNitro Update Available",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            Process.Start(new ProcessStartInfo(DownloadPage) { UseShellExecute = true });
        } catch { }
    }
}

// ── Data monitors ────────────────────────────────────────────────────────────
static class CpuMonitor {
    static PerformanceCounter _total;
    static readonly List<PerformanceCounter> _cores = new List<PerformanceCounter>();
    static float _lastTotal;
    static bool _init;
    static string _cpuName = "Processor";
    static int _physical = 1, _logical = 1;
    static float _baseMHz;

    static void EnsureInit() {
        if (_init) return;
        _init = true;
        try {
            _total = new PerformanceCounter("Processor", "% Processor Time", "_Total");
            _total.NextValue();
            var cat = new PerformanceCounterCategory("Processor");
            foreach (var inst in cat.GetInstanceNames()) {
                if (inst == "_Total") continue;
                var c = new PerformanceCounter("Processor", "% Processor Time", inst);
                c.NextValue();
                _cores.Add(c);
            }
            using var s = new ManagementObjectSearcher("SELECT Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed FROM Win32_Processor");
            foreach (ManagementObject o in s.Get()) {
                _cpuName = (o["Name"]?.ToString() ?? "Processor").Trim();
                _physical = Convert.ToInt32(o["NumberOfCores"]);
                _logical = Convert.ToInt32(o["NumberOfLogicalProcessors"]);
                _baseMHz = Convert.ToSingle(o["MaxClockSpeed"]);
                break;
            }
        } catch { }
    }

    public static string CpuName { get { EnsureInit(); return _cpuName; } }
    public static int PhysicalCores { get { EnsureInit(); return _physical; } }
    public static int LogicalCores { get { EnsureInit(); return _logical; } }
    public static float BaseMHz { get { EnsureInit(); return _baseMHz; } }

    public static float Usage {
        get {
            EnsureInit();
            try { _lastTotal = _total.NextValue(); } catch { }
            return _lastTotal;
        }
    }

    public static float BoostMHz => BaseMHz + (BaseMHz * 0.28f) * (Usage / 100f);

    public static float[] CoreUsages {
        get {
            EnsureInit();
            var r = new float[_cores.Count];
            for (int i = 0; i < _cores.Count; i++) {
                try { r[i] = _cores[i].NextValue(); } catch { }
            }
            return r;
        }
    }

    public static float Temp {
        get {
            try {
                using var searcher = new ManagementObjectSearcher(@"root\wmi", "SELECT * FROM MSAcpi_ThermalZoneTemperature");
                foreach (ManagementObject obj in searcher.Get()) {
                    double raw = Convert.ToDouble(obj["CurrentTemperature"]);
                    return (float)((raw / 10.0) - 273.15);
                }
            } catch { }
            // Fallback estimate when WMI thermal zone unavailable
            return 35f + 15f * (Usage / 100f);
        }
    }

    public static string TempSource {
        get {
            try {
                using var searcher = new ManagementObjectSearcher(@"root\wmi", "SELECT * FROM MSAcpi_ThermalZoneTemperature");
                if (searcher.Get().Count > 0) return "WMI thermal zone";
            } catch { }
            return "Load-based estimate";
        }
    }
}

static class RamMonitor {
    [StructLayout(LayoutKind.Sequential)]
    struct MEMORYSTATUSEX {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys, ullAvailPhys;
        public ulong ullTotalPageFile, ullAvailPageFile;
        public ulong ullTotalVirtual, ullAvailVirtual, ullAvailExtendedVirtual;
    }
    [DllImport("kernel32.dll")] static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX buf);

    public static (float usedGB, float freeGB, float totalGB, float pct) Get() {
        var m = new MEMORYSTATUSEX { dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)) };
        GlobalMemoryStatusEx(ref m);
        float total = m.ullTotalPhys / 1073741824f;
        float avail = m.ullAvailPhys / 1073741824f;
        float used  = total - avail;
        return (used, avail, total, m.dwMemoryLoad);
    }
}

static class DiskMonitor {
    public static string VolumeLabel = "C:";
    public static float UsedGB, FreeGB, TotalGB, UsedPercent;

    public static void Poll() {
        try {
            var d = new DriveInfo("C");
            if (!d.IsReady) return;
            VolumeLabel = string.IsNullOrWhiteSpace(d.VolumeLabel) ? "C:" : d.VolumeLabel;
            TotalGB = d.TotalSize / 1073741824f;
            FreeGB = d.AvailableFreeSpace / 1073741824f;
            UsedGB = TotalGB - FreeGB;
            UsedPercent = TotalGB > 0 ? UsedGB / TotalGB * 100f : 0;
        } catch { }
    }
}

static class BatteryMonitor {
    public static bool IsPresent, IsCharging, IsFullyCharged;
    public static int LevelPercent;
    public static string ChargeRateText = "—";
    public static string PowerSource = "Unknown";
    public static int? TimeToFullMinutes;

    public static void Poll() {
        IsPresent = false;
        try {
            using var s = new ManagementObjectSearcher("SELECT EstimatedChargeRemaining, BatteryStatus FROM Win32_Battery");
            foreach (ManagementObject o in s.Get()) {
                IsPresent = true;
                LevelPercent = Convert.ToInt32(o["EstimatedChargeRemaining"]);
                int status = Convert.ToInt32(o["BatteryStatus"]);
                IsCharging = status == 2;
                IsFullyCharged = status == 3 || LevelPercent >= 100;
                PowerSource = IsCharging ? "AC Power" : "Battery Power";
                break;
            }
        } catch { }

        if (!IsPresent) {
            ChargeRateText = "Desktop";
            PowerSource = "AC / Desktop";
            return;
        }

        if (IsCharging && IsFullyCharged) ChargeRateText = "Full";
        else if (IsCharging) ChargeRateText = "Charging";
        else ChargeRateText = "On battery";
    }
}

static class BtcMonitor {
    static readonly HttpClient _http = new HttpClient { Timeout = TimeSpan.FromSeconds(8) };
    public static float Price, Change24h;
    public static bool HasData;

    public static async Task FetchLoop(CancellationToken ct) {
        _http.DefaultRequestHeaders.Add("User-Agent", "rNitro-Windows/4.2.1-Windows-Final-x86");
        while (!ct.IsCancellationRequested) {
            try {
                var url  = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true";
                var json = await _http.GetStringAsync(url);
                using var doc  = JsonDocument.Parse(json);
                var btc        = doc.RootElement.GetProperty("bitcoin");
                Price          = btc.GetProperty("usd").GetSingle();
                Change24h      = btc.GetProperty("usd_24h_change").GetSingle();
                HasData        = true;
            } catch { }
            try { await Task.Delay(30000, ct); } catch { break; }
        }
    }
}

static class StressTester {
    static CancellationTokenSource _cts;
    static System.Threading.Timer _timer;
    public static bool IsRunning => _cts != null && !_cts.IsCancellationRequested;
    public static int ElapsedSeconds;

    public static void Start() {
        Stop();
        _cts = new CancellationTokenSource();
        int n = Environment.ProcessorCount;
        for (int t = 0; t < n; t++) {
            Task.Run(() => {
                double x = 1;
                while (!_cts.Token.IsCancellationRequested) {
                    for (int i = 0; i < 5000; i++) x = Math.Sin(x) * Math.Cos(x) + Math.Sqrt(Math.Abs(x) + 1);
                }
            }, _cts.Token);
        }
        ElapsedSeconds = 0;
        _timer = new System.Threading.Timer(_ => ElapsedSeconds++, null, 1000, 1000);
    }

    public static void Stop() {
        _cts?.Cancel();
        _timer?.Dispose();
        _timer = null;
        _cts = null;
    }
}

static class BenchmarkRunner {
    public static bool IsRunning;
    public static float? SingleScore, MultiScore;
    public static string Stage = "";
    public static float Progress;

    public static void Run() {
        if (IsRunning) return;
        Task.Run(async () => {
            IsRunning = true;
            SingleScore = null;
            MultiScore = null;
            Stage = "1-core"; Progress = 0.1f;
            SingleScore = RunBench(1);
            Progress = 0.55f;
            Stage = "Multi"; 
            MultiScore = RunBench(Environment.ProcessorCount);
            Progress = 1f;
            Stage = "Done";
            await Task.Delay(400);
            IsRunning = false;
            Stage = "";
            Progress = 0;
        });
    }

    static float RunBench(int threads) {
        var sw = Stopwatch.StartNew();
        long total = 0;
        while (sw.ElapsedMilliseconds < 2500) {
            Parallel.For(0, threads, _ => {
                double x = 1;
                for (int i = 0; i < 8000; i++) x = Math.Sqrt(x + i * 0.001);
                Interlocked.Increment(ref total);
            });
        }
        return total / (sw.ElapsedMilliseconds / 1000f);
    }
}

// ── System tray context ───────────────────────────────────────────────────────
class RNitroContext : ApplicationContext {
    NotifyIcon _tray;
    MainPopupForm _popup;
    System.Windows.Forms.Timer _timer;
    CancellationTokenSource _cts = new CancellationTokenSource();

    const int HISTORY = 67;
    readonly Queue<float> _cpuHistory = new Queue<float>(HISTORY);

    public RNitroContext() {
        for (int i = 0; i < HISTORY; i++) _cpuHistory.Enqueue(0);

        _popup = new MainPopupForm();
        _tray = new NotifyIcon { Visible = true, Text = "rNitro", Icon = MakeIcon(0) };
        _tray.MouseClick += OnTrayClick;

        var menu = new ContextMenuStrip();
        menu.Items.Add("rNitro v4.2.1-Windows-Final-x86").Enabled = false;
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Exit", null, (s, e) => { _cts.Cancel(); _tray.Visible = false; Application.Exit(); });
        _tray.ContextMenuStrip = menu;

        _timer = new System.Windows.Forms.Timer { Interval = 900 };
        _timer.Tick += OnTick;
        _timer.Start();
        OnTick(null, null);

        Task.Run(() => BtcMonitor.FetchLoop(_cts.Token));
        Task.Run(async () => await UpdateChecker.CheckOnLaunchAsync());
    }

    void OnTick(object s, EventArgs e) {
        float cpu = CpuMonitor.Usage;
        float temp = CpuMonitor.Temp;
        var (usedGB, freeGB, totalGB, ramPct) = RamMonitor.Get();
        DiskMonitor.Poll();
        BatteryMonitor.Poll();

        Push(_cpuHistory, cpu);
        _tray.Icon = MakeIcon((int)cpu);

        string tempStr = $"{temp:F0}°C";
        string btcStr = BtcMonitor.HasData ? $"₿ ${BtcMonitor.Price:N0}" : "₿ …";
        _tray.Text = $"{btcStr}  CPU: {cpu:F0}%  {tempStr}  RAM: {usedGB:F1}/{totalGB:F1}GB";

        if (_popup.Visible) _popup.RefreshData(_cpuHistory.ToArray());
    }

    void OnTrayClick(object s, MouseEventArgs e) {
        if (e.Button != MouseButtons.Left) return;
        if (_popup.Visible) { _popup.Hide(); return; }

        var screen = Screen.PrimaryScreen.WorkingArea;
        var cursor = Cursor.Position;
        _popup.Left = Math.Max(screen.Left, Math.Min(cursor.X - _popup.Width / 2, screen.Right - _popup.Width));
        _popup.Top  = Math.Max(screen.Top, screen.Bottom - _popup.Height - 12);
        _popup.Show();
        _popup.BringToFront();
        _popup.RefreshData(_cpuHistory.ToArray());
    }

    static void Push(Queue<float> q, float v) {
        if (q.Count >= HISTORY) q.Dequeue();
        q.Enqueue(v);
    }

    static Icon MakeIcon(int pct) {
        using var bmp = new Bitmap(16, 16);
        using var g   = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.Clear(Color.Transparent);
        using var bg = new SolidBrush(Color.FromArgb(30, 30, 45));
        g.FillEllipse(bg, 1, 1, 14, 14);
        Color arc = Theme.Usage(pct);
        using var pen = new Pen(arc, 3f);
        g.DrawArc(pen, 2, 2, 12, 12, -90, 360f * pct / 100f);
        using var border = new Pen(Color.FromArgb(60, 255, 255, 255), 0.5f);
        g.DrawEllipse(border, 1, 1, 14, 14);
        return Icon.FromHandle(bmp.GetHicon());
    }
}

// ── Main popup (macOS-style) ──────────────────────────────────────────────────
class MainPopupForm : Form {
    Panel _monitorPanel;

    // Monitor controls
    Label _cpuNameLbl, _cpuPctLbl, _btcLbl;
    StatCellControl _baseCell, _boostCell, _tempCell, _coresCell;
    StatCellControl _batteryCell, _chargeCell;
    GraphPanel _cpuGraph;
    UsageBarControl _ramBar, _ssdBar;
    FlowLayoutPanel _coreFlow;
    Label _stressTimeLbl;
    Button _stressBtn, _benchBtn;
    Label _benchSingleLbl, _benchMultiLbl, _benchStageLbl;
    Panel _benchProgress;

    readonly List<CoreRowControl> _coreRows = new List<CoreRowControl>();

    public MainPopupForm() {
        FormBorderStyle = FormBorderStyle.None;
        StartPosition   = FormStartPosition.Manual;
        TopMost         = true;
        ShowInTaskbar   = false;
        BackColor       = Theme.BG;
        Width           = 400;
        Height          = 560;

        var regionPath = UiHelper.RoundedRect(new Rectangle(0, 0, Width, Height), 14);
        Region = new Region(regionPath);

        BuildMonitorPanel();
        _monitorPanel.Dock = DockStyle.Fill;
        Controls.Add(_monitorPanel);

        Deactivate += (s, e) => Hide();
        Paint += (s, e) => {
            using var pen = new Pen(Theme.Border, 1);
            e.Graphics.DrawPath(pen, UiHelper.RoundedRect(new Rectangle(0, 0, Width - 1, Height - 1), 14));
        };

        BuildCoreRows();
    }

    void BuildMonitorPanel() {
        _monitorPanel = new Panel {
            Dock = DockStyle.Fill,
            AutoScroll = true,
            BackColor = Theme.BG,
            Padding = new Padding(0, 0, 0, 8)
        };

        int y = 0;
        var header = new Panel { Location = new Point(0, y), Size = new Size(384, 44), BackColor = Color.Transparent };
        var title = UiHelper.MakeLabel("rNitro", 15, FontStyle.Bold, Theme.Text);
        title.Location = new Point(16, 8);
        _cpuNameLbl = UiHelper.MakeLabel("…", 9, FontStyle.Regular, Theme.Dim);
        _cpuNameLbl.Location = new Point(16, 26);
        _cpuNameLbl.Size = new Size(260, 14);
        var liveDot = new Panel { BackColor = Theme.Green, Size = new Size(6, 6), Location = new Point(330, 12) };
        liveDot.Paint += (s, e) => {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using var b = new SolidBrush(Theme.Green);
            e.Graphics.FillEllipse(b, 0, 0, 5, 5);
        };
        var liveLbl = UiHelper.MakeLabel("Live", 9, FontStyle.Regular, Theme.Dim);
        liveLbl.Location = new Point(340, 8);
        _btcLbl = UiHelper.MakeLabel("", 9, FontStyle.Regular, Theme.Orange);
        _btcLbl.Location = new Point(300, 24);
        _btcLbl.Size = new Size(80, 14);
        _btcLbl.TextAlign = ContentAlignment.TopRight;
        header.Controls.AddRange(new Control[] { title, _cpuNameLbl, liveDot, liveLbl, _btcLbl });
        y += 44;
        _monitorPanel.Controls.Add(header);
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        var stats1 = new Panel { Location = new Point(0, y), Size = new Size(384, 68), BackColor = Color.Transparent };
        _baseCell  = new StatCellControl("BASE", "—", "MHz", Theme.Text, () => ShowDetail("clock"));
        _boostCell = new StatCellControl("BOOST", "—", "MHz", Theme.Cyan, () => ShowDetail("clock"));
        _tempCell  = new StatCellControl("TEMP", "—", "°C", Theme.Cyan, () => ShowDetail("temp"));
        _coresCell = new StatCellControl("CORES", "—", "threads", Theme.Green, () => ShowDetail("cores"));
        LayoutStatRow(stats1, new[] { _baseCell, _boostCell, _tempCell, _coresCell });
        _monitorPanel.Controls.Add(stats1); y += 68;
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        var stats2 = new Panel { Location = new Point(0, y), Size = new Size(384, 68), BackColor = Color.Transparent };
        _batteryCell = new StatCellControl("BATTERY", "—", "%", Theme.Cyan, () => ShowDetail("battery"));
        _chargeCell  = new StatCellControl("CHARGE", "—", "status", Theme.Dim, () => ShowDetail("battery"));
        LayoutStatRow(stats2, new[] { _batteryCell, _chargeCell, new StatCellControl("", "", "", Theme.Dim), new StatCellControl("", "", "", Theme.Dim) });
        _batteryCell.Width = 192; _chargeCell.Width = 192;
        _monitorPanel.Controls.Add(stats2); y += 68;
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        var cpuSec = new Panel { Location = new Point(0, y), Size = new Size(384, 70), BackColor = Color.Transparent };
        var cpuHead = UiHelper.MakeLabel("CPU", 10, FontStyle.Regular, Theme.Dim);
        cpuHead.Location = new Point(16, 4);
        _cpuPctLbl = UiHelper.MakeLabel("0%", 13, FontStyle.Bold, Theme.Green);
        _cpuPctLbl.Location = new Point(330, 2);
        _cpuPctLbl.Size = new Size(50, 20);
        _cpuPctLbl.TextAlign = ContentAlignment.TopRight;
        _cpuGraph = new GraphPanel { Bounds = new Rectangle(16, 26, 368, 36), LineColor = Theme.Green };
        cpuSec.Controls.AddRange(new Control[] { cpuHead, _cpuPctLbl, _cpuGraph });
        _monitorPanel.Controls.Add(cpuSec); y += 70;
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        _ramBar = new UsageBarControl("RAM");
        _ramBar.Location = new Point(0, y);
        _ramBar.Width = 384;
        _ssdBar = new UsageBarControl("SSD");
        _ssdBar.Location = new Point(0, y + 44);
        _ssdBar.Width = 384;
        _ramBar.DetailClick = () => ShowDetail("memory");
        _ssdBar.DetailClick = () => ShowDetail("storage");
        _monitorPanel.Controls.Add(_ramBar);
        _monitorPanel.Controls.Add(_ssdBar); y += 88;
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        var coreHead = new Panel { Location = new Point(0, y), Size = new Size(384, 20), BackColor = Color.Transparent };
        var coresLbl = UiHelper.MakeLabel("Cores", 10, FontStyle.Regular, Theme.Dim);
        coresLbl.Location = new Point(16, 2);
        var coresMeta = UiHelper.MakeLabel("", 9, FontStyle.Regular, Theme.Dim);
        coresMeta.Location = new Point(280, 4);
        coresMeta.Size = new Size(100, 14);
        coresMeta.TextAlign = ContentAlignment.TopRight;
        coresMeta.Name = "coresMeta";
        coreHead.Controls.AddRange(new Control[] { coresLbl, coresMeta });
        _monitorPanel.Controls.Add(coreHead); y += 22;

        _coreFlow = new FlowLayoutPanel {
            Location = new Point(16, y),
            Size = new Size(368, 120),
            FlowDirection = FlowDirection.TopDown,
            WrapContents = false,
            AutoScroll = false,
            BackColor = Color.Transparent
        };
        _monitorPanel.Controls.Add(_coreFlow); y += 124;
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        var stressSec = new Panel { Location = new Point(0, y), Size = new Size(384, 40), BackColor = Color.Transparent };
        var stressLbl = UiHelper.MakeLabel("Stress", 10, FontStyle.Regular, Theme.Dim);
        stressLbl.Location = new Point(16, 4);
        _stressTimeLbl = UiHelper.MakeLabel("", 9, FontStyle.Regular, Theme.Dim);
        _stressTimeLbl.Location = new Point(16, 20);
        _stressBtn = UiHelper.MakeButton("Start", Theme.Orange);
        _stressBtn.Location = new Point(300, 8);
        _stressBtn.Click += (s, e) => {
            if (StressTester.IsRunning) StressTester.Stop();
            else StressTester.Start();
        };
        stressSec.Controls.AddRange(new Control[] { stressLbl, _stressTimeLbl, _stressBtn });
        _monitorPanel.Controls.Add(stressSec); y += 40;
        _monitorPanel.Controls.Add(UiHelper.Divider(y)); y += 9;

        var benchSec = new Panel { Location = new Point(0, y), Size = new Size(384, 72), BackColor = Color.Transparent };
        var benchHead = UiHelper.MakeLabel("Benchmark", 10, FontStyle.Regular, Theme.Dim);
        benchHead.Location = new Point(16, 4);
        _benchStageLbl = UiHelper.MakeLabel("", 9, FontStyle.Regular, Theme.Dim);
        _benchStageLbl.Location = new Point(280, 4);
        _benchStageLbl.Size = new Size(100, 14);
        _benchStageLbl.TextAlign = ContentAlignment.TopRight;

        var singleBox = new Panel { Location = new Point(16, 24), Size = new Size(100, 40), BackColor = Color.Transparent };
        singleBox.Controls.Add(UiHelper.MakeLabel("1-core", 8, FontStyle.Regular, Theme.Dim));
        singleBox.Controls[0].Location = new Point(0, 0);
        _benchSingleLbl = UiHelper.MakeLabel("—", 14, FontStyle.Bold, Theme.Cyan);
        _benchSingleLbl.Location = new Point(0, 14);

        var multiBox = new Panel { Location = new Point(130, 24), Size = new Size(100, 40), BackColor = Color.Transparent };
        multiBox.Controls.Add(UiHelper.MakeLabel("Multi", 8, FontStyle.Regular, Theme.Dim));
        multiBox.Controls[0].Location = new Point(0, 0);
        _benchMultiLbl = UiHelper.MakeLabel("—", 14, FontStyle.Bold, Theme.Green);
        _benchMultiLbl.Location = new Point(0, 14);

        _benchBtn = UiHelper.MakeButton("Run", Theme.Cyan);
        _benchBtn.Location = new Point(300, 28);
        _benchBtn.Click += (s, e) => BenchmarkRunner.Run();

        _benchProgress = new Panel { BackColor = Theme.Border, Location = new Point(16, 66), Size = new Size(368, 2) };

        benchSec.Controls.AddRange(new Control[] { benchHead, _benchStageLbl, singleBox, _benchSingleLbl, multiBox, _benchMultiLbl, _benchBtn, _benchProgress });
        benchSec.Controls.Remove(_benchSingleLbl);
        benchSec.Controls.Remove(_benchMultiLbl);
        singleBox.Controls.Add(_benchSingleLbl);
        multiBox.Controls.Add(_benchMultiLbl);
        benchSec.Controls.Add(singleBox);
        benchSec.Controls.Add(multiBox);
        _monitorPanel.Controls.Add(benchSec);
    }

    void BuildCoreRows() {
        _coreFlow.Controls.Clear();
        _coreRows.Clear();
        int n = Math.Max(1, CpuMonitor.LogicalCores);
        for (int i = 0; i < n; i++) {
            var row = new CoreRowControl(i);
            row.Width = 368;
            row.Height = 18;
            _coreRows.Add(row);
            _coreFlow.Controls.Add(row);
        }
        int h = Math.Min(200, n * 20 + 4);
        _coreFlow.Height = h;
    }

    static void LayoutStatRow(Panel p, StatCellControl[] cells) {
        int w = 96;
        for (int i = 0; i < cells.Length; i++) {
            cells[i].Bounds = new Rectangle(8 + i * w, 4, w, 60);
            p.Controls.Add(cells[i]);
        }
    }

    public void RefreshData(float[] cpuHist) {
        float cpu = CpuMonitor.Usage;
        float temp = CpuMonitor.Temp;
        var (usedGB, freeGB, totalGB, ramPct) = RamMonitor.Get();

        _cpuNameLbl.Text = CpuMonitor.CpuName;
        if (BtcMonitor.HasData)
            _btcLbl.Text = $"₿ ${BtcMonitor.Price:N0}";

        _baseCell.SetValue($"{CpuMonitor.BaseMHz:F0}");
        _boostCell.SetValue($"{CpuMonitor.BoostMHz:F0}");
        _tempCell.SetValue($"{temp:F0}");
        _tempCell.ValueColor = Theme.Temp(temp);
        _coresCell.SetValue($"{CpuMonitor.LogicalCores}");

        if (BatteryMonitor.IsPresent) {
            _batteryCell.SetValue($"{BatteryMonitor.LevelPercent}");
            _batteryCell.ValueColor = BatteryMonitor.IsCharging ? Theme.Green : Theme.Cyan;
            _chargeCell.SetValue(BatteryMonitor.ChargeRateText);
            _chargeCell.UnitText = BatteryMonitor.IsCharging ? "charging" : "status";
            _chargeCell.ValueColor = BatteryMonitor.IsCharging ? Theme.Orange : Theme.Dim;
        } else {
            _batteryCell.SetValue("—");
            _chargeCell.SetValue("N/A");
            _chargeCell.UnitText = "desktop";
        }

        _cpuPctLbl.Text = $"{cpu:F1}%";
        _cpuPctLbl.ForeColor = Theme.Usage(cpu);
        _cpuGraph.LineColor = Theme.Usage(cpu);
        if (cpuHist != null) _cpuGraph.SetData(cpuHist);

        _ramBar.SetData(usedGB, freeGB, totalGB, ramPct);
        _ssdBar.Label = $"SSD · {DiskMonitor.VolumeLabel}";
        _ssdBar.SetData(DiskMonitor.UsedGB, DiskMonitor.FreeGB, DiskMonitor.TotalGB, DiskMonitor.UsedPercent);

        var coreUsages = CpuMonitor.CoreUsages;
        if (_coreRows.Count != coreUsages.Length && coreUsages.Length > 0) BuildCoreRows();
        for (int i = 0; i < Math.Min(_coreRows.Count, coreUsages.Length); i++)
            _coreRows[i].SetUsage(coreUsages[i]);

        foreach (Control c in _monitorPanel.Controls) {
            if (c is Panel p && p.Controls.Count > 0) {
                foreach (Control cc in p.Controls) {
                    if (cc.Name == "coresMeta") {
                        ((Label)cc).Text = $"{CpuMonitor.PhysicalCores}P / {CpuMonitor.LogicalCores}L";
                    }
                }
            }
        }

        if (StressTester.IsRunning) {
            _stressBtn.Text = "Stop";
            _stressBtn.BackColor = Theme.Red;
            _stressTimeLbl.Text = $"{StressTester.ElapsedSeconds / 60:D2}:{StressTester.ElapsedSeconds % 60:D2}";
        } else {
            _stressBtn.Text = "Start";
            _stressBtn.BackColor = Theme.Orange;
            _stressTimeLbl.Text = "";
        }

        _stressBtn.Enabled = !BenchmarkRunner.IsRunning;
        _benchBtn.Enabled = !BenchmarkRunner.IsRunning && !StressTester.IsRunning;
        _benchBtn.Text = BenchmarkRunner.IsRunning ? "Running…" : "Run";
        _benchSingleLbl.Text = BenchmarkRunner.SingleScore.HasValue ? $"{BenchmarkRunner.SingleScore:F0}" : "—";
        _benchMultiLbl.Text = BenchmarkRunner.MultiScore.HasValue ? $"{BenchmarkRunner.MultiScore:F0}" : "—";
        _benchStageLbl.Text = BenchmarkRunner.Stage;
        _benchProgress.Invalidate();
    }

    void ShowDetail(string kind) {
        var lines = new List<string>();
        switch (kind) {
            case "clock":
                lines.Add($"CPU: {CpuMonitor.CpuName}");
                lines.Add($"Base: {CpuMonitor.BaseMHz:F0} MHz");
                lines.Add($"Boost: {CpuMonitor.BoostMHz:F0} MHz");
                lines.Add($"Max theoretical: {CpuMonitor.BaseMHz * 1.28f:F0} MHz");
                lines.Add("Source: Win32_Processor MaxClockSpeed");
                break;
            case "temp":
                lines.Add($"Current: {CpuMonitor.Temp:F1} °C");
                lines.Add($"Source: {CpuMonitor.TempSource}");
                break;
            case "cores":
                lines.Add($"Physical cores: {CpuMonitor.PhysicalCores}");
                lines.Add($"Logical threads: {CpuMonitor.LogicalCores}");
                break;
            case "memory":
                var m = RamMonitor.Get();
                lines.Add($"Used: {m.usedGB:F2} GB");
                lines.Add($"Free: {m.freeGB:F2} GB");
                lines.Add($"Total: {m.totalGB:F2} GB");
                lines.Add($"Load: {m.pct:F0}%");
                break;
            case "storage":
                lines.Add($"Volume: {DiskMonitor.VolumeLabel}");
                lines.Add($"Used: {DiskMonitor.UsedGB:F1} GB");
                lines.Add($"Free: {DiskMonitor.FreeGB:F1} GB");
                lines.Add($"Total: {DiskMonitor.TotalGB:F1} GB");
                break;
            case "battery":
                if (!BatteryMonitor.IsPresent) { lines.Add("No battery detected (desktop PC)."); break; }
                lines.Add($"Level: {BatteryMonitor.LevelPercent}%");
                lines.Add($"Status: {BatteryMonitor.ChargeRateText}");
                lines.Add($"Power: {BatteryMonitor.PowerSource}");
                break;
        }
        MessageBox.Show(string.Join("\n", lines), "rNitro Details", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}

// ── UI helpers & controls ─────────────────────────────────────────────────────
static class UiHelper {
    public static Label MakeLabel(string text, float size, FontStyle style, Color color) =>
        new Label {
            Text = text,
            Font = Theme.Font(size, style),
            ForeColor = color,
            BackColor = Color.Transparent,
            AutoSize = true
        };

    public static Button MakeButton(string text, Color tint) =>
        new Button {
            Text = text,
            FlatStyle = FlatStyle.Flat,
            BackColor = tint,
            ForeColor = Color.Black,
            Font = Theme.Font(9, FontStyle.Bold),
            Size = new Size(72, 26),
            Cursor = Cursors.Hand
        };

    public static Panel Divider(int y) =>
        new Panel { BackColor = Theme.Border, Location = new Point(16, y), Size = new Size(368, 1) };

    public static GraphicsPath RoundedRect(Rectangle r, int radius) {
        var path = new GraphicsPath();
        int d = radius * 2;
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}

class StatCellControl : Panel {
    readonly Label _title, _value, _unit;
    readonly Action _onClick;

    public Color ValueColor {
        get => _value.ForeColor;
        set => _value.ForeColor = value;
    }

    public string UnitText {
        get => _unit.Text;
        set => _unit.Text = value;
    }

    public StatCellControl(string title, string value, string unit, Color color, Action onClick = null) {
        _onClick = onClick;
        BackColor = Color.Transparent;
        Cursor = onClick != null ? Cursors.Hand : Cursors.Default;
        _title = UiHelper.MakeLabel(title, 8, FontStyle.Regular, Theme.Dim);
        _title.Location = new Point(0, 0);
        _value = UiHelper.MakeLabel(value, 16, FontStyle.Bold, color);
        _value.Location = new Point(0, 14);
        _unit = UiHelper.MakeLabel(unit, 8, FontStyle.Regular, Theme.Dim);
        _unit.Location = new Point(0, 38);
        Controls.AddRange(new Control[] { _title, _value, _unit });
        if (onClick != null) {
            Click += (s, e) => onClick();
            foreach (Control c in Controls) c.Click += (s, e) => onClick();
        }
    }

    public void SetValue(string v) => _value.Text = v;
}

class UsageBarControl : Panel {
    readonly Label _label, _detail;
    float _used, _free, _total, _pct;
    public Action DetailClick;

    public string Label {
        get => _label.Text;
        set => _label.Text = value;
    }

    public UsageBarControl(string label) {
        Height = 40;
        BackColor = Color.Transparent;
        _label = UiHelper.MakeLabel(label, 10, FontStyle.Regular, Theme.Dim);
        _label.Location = new Point(16, 0);
        _detail = UiHelper.MakeLabel("", 9, FontStyle.Regular, Theme.Dim);
        _detail.Location = new Point(200, 0);
        _detail.Size = new Size(184, 14);
        _detail.TextAlign = ContentAlignment.TopRight;
        Cursor = Cursors.Hand;
        Click += (s, e) => DetailClick?.Invoke();
        Controls.AddRange(new Control[] { _label, _detail });
    }

    public void SetData(float used, float free, float total, float pct) {
        _used = used; _free = free; _total = total; _pct = pct;
        _detail.Text = $"{used:F1} / {total:F1} GB  ({pct:F0}%)";
        Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        var bar = new Rectangle(16, 22, 368, 8);
        using var bg = new SolidBrush(Theme.Card);
        g.FillRectangle(bg, bar);
        int fillW = (int)(bar.Width * Math.Max(0, Math.Min(1, _pct / 100f)));
        if (fillW > 0) {
            using var fg = new SolidBrush(Theme.Usage(_pct));
            g.FillRectangle(fg, bar.X, bar.Y, fillW, bar.Height);
        }
    }
}

class CoreRowControl : Panel {
    readonly Label _name;
    readonly Panel _bar;
    float _usage;

    public CoreRowControl(int index) {
        BackColor = Color.Transparent;
        _name = UiHelper.MakeLabel($"Core {index}", 9, FontStyle.Regular, Theme.Dim);
        _name.Location = new Point(0, 2);
        _name.Size = new Size(56, 14);
        _bar = new Panel { Location = new Point(60, 4), Size = new Size(260, 10), BackColor = Theme.Card };
        var pctLbl = UiHelper.MakeLabel("0%", 9, FontStyle.Regular, Theme.Dim);
        pctLbl.Location = new Point(326, 2);
        pctLbl.Size = new Size(40, 14);
        pctLbl.TextAlign = ContentAlignment.TopRight;
        pctLbl.Name = "pct";
        Controls.AddRange(new Control[] { _name, _bar, pctLbl });
    }

    public void SetUsage(float u) {
        _usage = u;
        foreach (Control c in Controls) {
            if (c.Name == "pct") c.Text = $"{u:F0}%";
        }
        _bar.Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        int w = (int)(_bar.Width * Math.Max(0, Math.Min(1, _usage / 100f)));
        if (w <= 0) return;
        using var b = new SolidBrush(Theme.Usage(_usage));
        e.Graphics.FillRectangle(b, _bar.Left, _bar.Top, w, _bar.Height);
    }
}

class GraphPanel : Panel {
    float[] _data = Array.Empty<float>();
    public Color LineColor { get; set; } = Theme.Green;

    public GraphPanel() {
        DoubleBuffered = true;
        BackColor = Theme.Card;
        Resize += (s, e) => Region = new Region(UiHelper.RoundedRect(new Rectangle(0, 0, Width, Height), 6));
    }

    public void SetData(float[] data) { _data = data ?? Array.Empty<float>(); Invalidate(); }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        if (_data.Length < 2) return;
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        int w = Width, h = Height;
        float step = (float)w / (_data.Length - 1);
        var pts = new List<PointF>();
        for (int i = 0; i < _data.Length; i++)
            pts.Add(new PointF(i * step, h - _data[i] / 100f * (h - 4) - 2));
        var fill = new List<PointF>(pts) { new PointF(w, h), new PointF(0, h) };
        using var fillBrush = new SolidBrush(Color.FromArgb(40, LineColor));
        g.FillPolygon(fillBrush, fill.ToArray());
        using var pen = new Pen(LineColor, 1.5f);
        g.DrawLines(pen, pts.ToArray());
    }
}
